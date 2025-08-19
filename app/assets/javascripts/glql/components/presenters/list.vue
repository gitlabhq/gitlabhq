<script>
import { GlIcon, GlIntersperse, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import FieldPresenter from './field.vue';

const DEFAULT_PAGE_SIZE = 5;

export default {
  name: 'ListPresenter',
  components: {
    GlIcon,
    GlIntersperse,
    GlLink,
    GlSprintf,
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
    fieldsExceptTitle() {
      return this.fields?.filter((item) => item.key !== 'title');
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
      class="!gl-m-0 gl-list-inside !gl-px-5 !gl-py-3 gl-transition-background hover:gl-bg-strong dark:hover:gl-bg-neutral-700"
      :class="{
        'gl-border-b !gl-border-b-section': itemIndex !== items.length - 1 || loading,
      }"
      :data-testid="`list-item-${itemIndex}`"
    >
      <div
        class="gl-str-truncated gl-inline-block gl-max-w-[calc(100%-40px)] gl-pl-2 gl-pt-1 gl-align-top"
      >
        <h3 class="!gl-heading-5 !gl-mb-1 gl-truncate">
          <field-presenter :item="item" field-key="title" />
        </h3>
        <div>
          <gl-intersperse separator=" · ">
            <span v-for="field in fieldsExceptTitle" :key="field.key">
              <field-presenter :item="item" :field-key="field.key" />
            </span>
          </gl-intersperse>
        </div>
      </div>
    </li>
    <template v-if="loading">
      <li
        v-for="i in pageSize"
        :key="i"
        class="!gl-m-0 gl-list-inside !gl-px-5 !gl-py-3 gl-transition-background hover:gl-bg-strong dark:hover:gl-bg-neutral-700"
        :class="{ 'gl-border-b !gl-border-b-section': i !== pageSize }"
      >
        <div class="gl-inline-block gl-align-top">
          <gl-skeleton-loader :width="400" :lines="1" :equal-width-lines="true" />
        </div>
      </li>
    </template>
  </component>
</template>
