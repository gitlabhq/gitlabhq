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
    class="mr-widget-body media gl-flex gl-items-center gl-py-4 gl-pl-5 gl-pr-4"
    :class="wrapperClasses"
    v-on="$listeners"
  >
    <div v-if="isLoading" class="mr-state-loader gl-w-full">
      <slot name="loading">
        <div class="gl-flex">
          <status-icon status="loading" />
          <div class="media-body gl-flex gl-items-center">
            <slot></slot>
          </div>
        </div>
      </slot>
    </div>
    <template v-else>
      <slot name="icon">
        <status-icon :status="status" />
      </slot>
      <div class="gl-flex gl-w-full">
        <div
          :class="{
            'gl-flex gl-items-center': actions.length,
            'gl-flex-wrap gl-items-center gl-gap-3 md:gl-flex': !actions.length,
          }"
          class="media-body gl-leading-normal"
        >
          <slot></slot>
        </div>
        <div
          :class="{
            'state-container-action-buttons gl-flex-wrap lg:gl-justify-end': !actions.length,
            'gl-pt-3 md:gl-pt-0': hasActionsSlot,
          }"
          class="gl-font-size-0 gl-flex gl-gap-3"
        >
          <slot name="actions">
            <actions v-if="actions.length" :tertiary-buttons="actions" />
          </slot>
        </div>
        <div
          v-if="isCollapsible"
          :class="{ 'md:gl-hidden': !collapseOnDesktop }"
          class="gl-border-l gl-ml-3 gl-h-6 gl-pl-3"
        >
          <gl-button
            v-gl-tooltip
            :title="collapsed ? expandDetailsTooltip : collapseDetailsTooltip"
            :aria-label="collapsed ? expandDetailsTooltip : collapseDetailsTooltip"
            :icon="collapsed ? 'chevron-lg-down' : 'chevron-lg-up'"
            category="tertiary"
            size="small"
            class="gl-align-top"
            data-testid="widget-toggle"
            @click="() => $emit('toggle')"
          />
        </div>
      </div>
    </template>
  </div>
</template>
