<script>
import { GlLoadingIcon } from '@gitlab/ui';
import PageHeading from './page_heading.vue';

export default {
  name: 'IndexLayout',
  components: {
    GlLoadingIcon,
    PageHeading,
  },
  props: {
    heading: {
      type: String,
      required: false,
      default: null,
    },
    headingTag: {
      type: String,
      required: false,
      default: null,
      validator: (value) => value === null || ['h1', 'h2'].includes(value),
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    pageHeadingSrOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="gl-index-layout">
    <slot name="before"></slot>
    <page-heading
      :heading="heading"
      :heading-tag="headingTag"
      :class="{ 'gl-sr-only': pageHeadingSrOnly }"
    >
      <template v-if="$scopedSlots['heading-wrapper']" #heading-wrapper>
        <slot name="heading-wrapper"></slot>
      </template>
      <template v-if="$scopedSlots.heading" #heading>
        <slot name="heading"></slot>
      </template>
      <template v-if="$scopedSlots.actions" #actions>
        <slot name="actions"></slot>
      </template>
      <template v-if="$scopedSlots.description || description" #description>
        <slot v-if="$scopedSlots.description" name="description"></slot>
        <template v-else>{{ description }}</template>
      </template>
    </page-heading>
    <div
      v-if="$scopedSlots.alerts"
      class="gl-index-layout-alerts js-index-layout-alerts"
      data-testid="index-layout-alerts"
    >
      <slot name="alerts"></slot>
    </div>
    <div data-testid="index-layout-content">
      <slot v-if="loading" name="loading">
        <gl-loading-icon class="gl-index-layout-loading-icon" size="lg" />
      </slot>
      <slot v-else></slot>
    </div>
  </div>
</template>
