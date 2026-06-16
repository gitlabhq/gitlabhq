<script>
import { GlIntersperse, GlSkeletonLoader } from '@gitlab/ui';
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
    hasTitle() {
      return this.fields?.some((field) => field.key === this.titleFieldKey);
    },
    visibleFields() {
      return this.hasTitle
        ? this.fields.filter((field) => field.key !== this.titleFieldKey)
        : this.fields;
    },
    pageSize() {
      return typeof this.loading === 'number' ? this.loading : DEFAULT_PAGE_SIZE;
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
          <field-presenter :item="item" :field-key="titleFieldKey" />
        </h3>
        <div>
          <gl-intersperse separator=" · ">
            <span v-for="field in visibleFields" :key="field.key">
              <field-presenter :item="item" :field-key="field.key" variant="compact" />
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
