<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  name: 'TimeTrackingCollapsedState',
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    showComparisonState: {
      type: Boolean,
      required: true,
    },
    showSpentOnlyState: {
      type: Boolean,
      required: true,
    },
    showEstimateOnlyState: {
      type: Boolean,
      required: true,
    },
    showNoTimeTrackingState: {
      type: Boolean,
      required: true,
    },
    timeSpentHumanReadable: {
      type: String,
      required: false,
      default: '',
    },
    timeEstimateHumanReadable: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    divClass() {
      if (this.showComparisonState) {
        return 'compare';
      }
      if (this.showEstimateOnlyState) {
        return 'estimate-only';
      }
      if (this.showSpentOnlyState) {
        return 'spend-only';
      }
      if (this.showNoTimeTrackingState) {
        return 'no-tracking';
      }

      return '';
    },
    spanClass() {
      if (this.showNoTimeTrackingState) {
        return 'no-value collapse-truncated-title gl-pt-2 gl-px-3 gl-text-sm';
      }

      return '';
    },
    text() {
      if (this.showComparisonState) {
        return `${this.timeSpentHumanReadable} / ${this.timeEstimateHumanReadable}`;
      }
      if (this.showEstimateOnlyState) {
        return `-- / ${this.timeEstimateHumanReadable}`;
      }
      if (this.showSpentOnlyState) {
        return `${this.timeSpentHumanReadable} / --`;
      }
      if (this.showNoTimeTrackingState) {
        return __('None');
      }

      return '';
    },
    timeTrackedTooltipText() {
      let title;
      if (this.showComparisonState) {
        title = __('Time remaining');
      } else if (this.showEstimateOnlyState) {
        title = __('Estimated');
      } else if (this.showSpentOnlyState) {
        title = __('Time spent');
      }

      return sprintf('%{title}: %{text}', { title, text: this.text });
    },
    tooltipText() {
      return this.showNoTimeTrackingState ? __('Time tracking') : this.timeTrackedTooltipText;
    },
  },
};
</script>

<template>
  <div
    v-gl-tooltip:body.viewport.left
    :title="tooltipText"
    data-testid="collapsedState"
    class="sidebar-collapsed-icon py-1 !gl-h-auto"
  >
    <gl-icon name="timer" />
    <div class="time-tracking-collapsed-summary">
      <div class="gl-px-4" :class="divClass">
        <span class="gl-text-sm" :class="spanClass"> {{ text }} </span>
      </div>
    </div>
  </div>
</template>
