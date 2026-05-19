<script>
import { GlLoadingIcon } from '@gitlab/ui';
import PageHeading from './page_heading.vue';

export default {
  name: 'DetailLayout',
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
  <div class="gl-detail-layout">
    <slot name="before"></slot>
    <page-heading
      :heading="heading"
      :heading-tag="headingTag"
      :class="{ 'gl-sr-only': pageHeadingSrOnly }"
    >
      <template v-if="$scopedSlots['heading-wrapper']" #heading-wrapper>
        <slot name="heading-wrapper"></slot>
      </template>
      <template v-else-if="$scopedSlots.heading" #heading>
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
      class="gl-detail-layout-alerts js-detail-layout-alerts"
      data-testid="detail-layout-alerts"
    >
      <slot name="alerts"></slot>
    </div>
    <slot v-if="loading" name="loading">
      <gl-loading-icon class="gl-detail-layout-loading-icon" size="lg" />
    </slot>
    <div
      v-else
      class="gl-detail-layout-container"
      :class="{ 'gl-detail-layout-container-has-sidebar': $scopedSlots.sidebar }"
      data-testid="detail-layout-container"
    >
      <div data-testid="detail-layout-content">
        <slot></slot>
      </div>
      <div v-if="$scopedSlots.sidebar" data-testid="detail-layout-sidebar">
        <slot name="sidebar"></slot>
      </div>
    </div>
  </div>
</template>
