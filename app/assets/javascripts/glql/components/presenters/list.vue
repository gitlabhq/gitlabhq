<script>
import { GlIntersperse, GlSkeletonLoader } from '@gitlab/ui';
import { baseFieldKeyOf, labelWithParameter } from '../../utils/chart_data';
import { FIELD_TYPES } from '../../constants';
import { titleFieldFor } from './presenter_registry';
import FieldPresenter from './field.vue';

const DEFAULT_PAGE_SIZE = 5;

export default {
  name: 'ListPresenter',
  components: {
    GlIntersperse,
    GlSkeletonLoader,
    FieldPresenter,
  },
  props: {
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
    },
    fields: {
      required: false,
      type: Array,
      default: () => [],
    },
    listType: {
      required: false,
      type: String,
      default: 'ul',
      validator: (value) => ['ul', 'ol'].includes(value),
    },
    loading: {
      required: false,
      type: [Boolean, Number],
      default: false,
    },
  },
  computed: {
    items() {
      return this.data.nodes || [];
    },
    titleFieldKey() {
      // Assumes a homogeneous typename for the result set: a single GLQL query
      // returns rows of one shape, so peeking at the first item is safe.
      // eslint-disable-next-line no-underscore-dangle
      return titleFieldFor(this.items[0]?.__typename);
    },
    // Matched on the base field so `title as "Name"` is still promoted and a
    // bucket dimension aliased `as "title"` stays an inline field.
    titleField() {
      return this.fields?.find((field) => baseFieldKeyOf(field) === this.titleFieldKey);
    },
    hasTitle() {
      return Boolean(this.titleField);
    },
    visibleFields() {
      return this.hasTitle ? this.fields.filter((field) => field !== this.titleField) : this.fields;
    },
    pageSize() {
      return typeof this.loading === 'number' ? this.loading : DEFAULT_PAGE_SIZE;
    },
  },
  methods: {
    baseFieldKeyOf,
    labelWithParameter,
    isMetric(field) {
      return field.type === FIELD_TYPES.METRIC;
    },
  },
};
</script>
<template>
  <component :is="listType" class="content-list !gl-mb-0" data-testid="list">
    <li
      v-for="(item, itemIndex) in items"
      :key="item.id || itemIndex"
      class="!gl-m-0 gl-list-inside !gl-px-5 !gl-py-3 gl-transition-background hover:gl-bg-subtle"
      :class="{
        'gl-border-b': itemIndex !== items.length - 1 || loading,
      }"
      :data-testid="`list-item-${itemIndex}`"
    >
      <div class="gl-inline-block gl-max-w-[calc(100%-40px)] gl-pl-2 gl-pt-1 gl-align-top">
        <h3 v-if="hasTitle" class="!gl-heading-5 !gl-mb-1 gl-truncate">
          <field-presenter
            :item="item"
            :field-key="titleField.key"
            :presenter-key="baseFieldKeyOf(titleField)"
          />
        </h3>
        <div>
          <gl-intersperse separator=" · ">
            <span v-for="field in visibleFields" :key="field.key">
              <template v-if="isMetric(field)">{{ labelWithParameter(field) }}: </template>
              <field-presenter
                :item="item"
                :field-key="field.key"
                :presenter-key="baseFieldKeyOf(field)"
                :parameters="field.parameters"
                variant="compact"
              />
            </span>
          </gl-intersperse>
        </div>
      </div>
    </li>
    <template v-if="loading">
      <li
        v-for="i in pageSize"
        :key="i"
        class="!gl-m-0 gl-list-inside !gl-px-5 !gl-py-3 gl-transition-background hover:gl-bg-subtle"
        :class="{ 'gl-border-b': i !== pageSize }"
      >
        <div class="gl-inline-block gl-align-top">
          <gl-skeleton-loader :width="400" :lines="1" :equal-width-lines="true" />
        </div>
      </li>
    </template>
  </component>
</template>
