<script>
import BaseLayout from './base_layout.vue';

export default {
  name: 'DetailLayout',
  components: { BaseLayout },
  props: {
    ...BaseLayout.props,
    showSidebar: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <base-layout
    :heading="heading"
    :heading-tag="headingTag"
    :description="description"
    :page-heading-sr-only="pageHeadingSrOnly"
    :loading="loading"
  >
    <template v-for="(_, name) in $scopedSlots" #[name]="slotProps">
      <slot :name="name" v-bind="slotProps || {}"></slot>
    </template>
    <template #content>
      <div
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
    </template>
  </base-layout>
</template>
