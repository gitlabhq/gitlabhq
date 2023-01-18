<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
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
  },
  i18n: {
    expandDetailsTooltip: __('Expand merge details'),
    collapseDetailsTooltip: __('Collapse merge details'),
  },
  computed: {
    wrapperClasses() {
      if (this.status === 'merged') return 'gl-bg-blue-50';
      if (this.status === 'closed') return 'gl-bg-red-50';
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
    class="mr-widget-body media gl-display-flex gl-align-items-center"
    :class="wrapperClasses"
    v-on="$listeners"
  >
    <div v-if="isLoading" class="gl-w-full mr-conflict-loader">
      <slot name="loading">
        <div class="gl-display-flex">
          <status-icon status="loading" />
          <div class="media-body">
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
          class="media-body gl-line-height-24"
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
          v-if="mr"
          class="gl-md-display-none gl-border-l-1 gl-border-l-solid gl-border-gray-100 gl-ml-3 gl-pl-3 gl-h-6 gl-mt-1"
        >
          <gl-button
            v-gl-tooltip
            :title="
              mr.mergeDetailsCollapsed
                ? $options.i18n.expandDetailsTooltip
                : $options.i18n.collapseDetailsTooltip
            "
            :icon="mr.mergeDetailsCollapsed ? 'chevron-lg-down' : 'chevron-lg-up'"
            category="tertiary"
            size="small"
            class="gl-vertical-align-top"
            @click="() => mr.toggleMergeDetails()"
          />
        </div>
      </div>
    </template>
  </div>
</template>
