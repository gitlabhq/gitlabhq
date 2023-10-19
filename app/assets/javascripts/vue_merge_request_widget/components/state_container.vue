<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import StatusIcon from './mr_widget_status_icon.vue';
import Actions from './action_buttons.vue';

export default {
  components: {
    GlButton,
    StatusIcon,
    Actions,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isCollapsible: {
      type: Boolean,
      required: false,
      default: false,
    },
    collapseOnDesktop: {
      type: Boolean,
      required: false,
      default: false,
    },
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
    mr: {
      type: Object,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: false,
      default: '',
    },
    actions: {
      type: Array,
      required: false,
      default: () => [],
    },
    expandDetailsTooltip: {
      required: false,
      type: String,
      default: __('Expand merge details'),
    },
    collapseDetailsTooltip: {
      required: false,
      type: String,
      default: __('Collapse merge details'),
    },
  },
  computed: {
    wrapperClasses() {
      if (this.status === STATUS_MERGED) return 'gl-bg-blue-50';
      if (this.status === STATUS_CLOSED) return 'gl-bg-red-50';
      return null;
    },
    hasActionsSlot() {
      return this.$scopedSlots.actions?.()?.length;
    },
  },
};
</script>

<template>
  <div
    class="mr-widget-body media gl-display-flex gl-align-items-center gl-pl-5 gl-pr-4 gl-py-4"
    :class="wrapperClasses"
    v-on="$listeners"
  >
    <div v-if="isLoading" class="gl-w-full mr-state-loader">
      <slot name="loading">
        <div class="gl-display-flex">
          <status-icon status="loading" />
          <div class="media-body gl-display-flex gl-align-items-center">
            <slot></slot>
          </div>
        </div>
      </slot>
    </div>
    <template v-else>
      <slot name="icon">
        <status-icon :status="status" />
      </slot>
      <div class="gl-display-flex gl-w-full">
        <div
          :class="{
            'gl-display-flex gl-align-items-center': actions.length,
            'gl-md-display-flex gl-align-items-center gl-flex-wrap gl-gap-3': !actions.length,
          }"
          class="media-body gl-line-height-normal"
        >
          <slot></slot>
          <div
            :class="{
              'state-container-action-buttons gl-flex-wrap gl-lg-justify-content-end': !actions.length,
              'gl-md-pt-0 gl-pt-3': hasActionsSlot,
            }"
            class="gl-display-flex gl-font-size-0 gl-gap-3"
          >
            <slot name="actions">
              <actions v-if="actions.length" :tertiary-buttons="actions" />
            </slot>
          </div>
        </div>
        <div
          v-if="isCollapsible"
          :class="{ 'gl-md-display-none': !collapseOnDesktop }"
          class="gl-border-l-1 gl-border-l-solid gl-border-gray-100 gl-ml-3 gl-pl-3 gl-h-6"
        >
          <gl-button
            v-gl-tooltip
            :title="collapsed ? expandDetailsTooltip : collapseDetailsTooltip"
            :aria-label="collapsed ? expandDetailsTooltip : collapseDetailsTooltip"
            :icon="collapsed ? 'chevron-lg-down' : 'chevron-lg-up'"
            category="tertiary"
            size="small"
            class="gl-vertical-align-top"
            data-testid="widget-toggle"
            @click="() => $emit('toggle')"
          />
        </div>
      </div>
    </template>
  </div>
</template>
