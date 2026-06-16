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
    showSidebar: {
      type: Boolean,
      required: false,
      default: true,
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
      :class="{ 'gl-detail-layout-container-has-sidebar': $scopedSlots.sidebar && showSidebar }"
      data-testid="detail-layout-container"
    >
      <div class="gl-detail-layout-content" data-testid="detail-layout-content">
        <slot></slot>
      </div>
      <div
        v-if="$scopedSlots.sidebar"
        class="gl-detail-layout-sidebar"
        :class="{ 'gl-contents': !showSidebar }"
        data-testid="detail-layout-sidebar"
        tabindex="0"
        role="region"
        :aria-label="__('Sidebar')"
      >
        <slot name="sidebar"></slot>
      </div>
      <div
        v-if="$scopedSlots.widgets"
        class="gl-detail-layout-widgets"
        data-testid="detail-layout-widgets"
      >
        <slot name="widgets"></slot>
      </div>
      <div
        v-if="$scopedSlots.activity"
        class="gl-detail-layout-activity"
        data-testid="detail-layout-activity"
      >
        <slot name="activity"></slot>
      </div>
    </div>
  </div>
</template>
