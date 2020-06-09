<script>
import { GlLoadingIcon } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Popover from '~/vue_shared/components/help_popover.vue';

/**
 * Renders the summary row for each report
 *
 * Used both in MR widget and Pipeline's view for:
 * - Unit tests reports
 * - Security reports
 */

export default {
  name: 'ReportSummaryRow',
  components: {
    CiIcon,
    Popover,
    GlLoadingIcon,
  },
  props: {
    summary: {
      type: String,
      required: true,
    },
    statusIcon: {
      type: String,
      required: true,
    },
    popoverOptions: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    iconStatus() {
      return {
        group: this.statusIcon,
        icon: `status_${this.statusIcon}`,
      };
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue report-block-list-issue-parent align-items-center">
    <div class="report-block-list-icon append-right-default">
      <gl-loading-icon
        v-if="statusIcon === 'loading'"
        css-class="report-block-list-loading-icon"
        size="md"
      />
      <ci-icon v-else :status="iconStatus" :size="24" />
    </div>
    <div class="report-block-list-issue-description">
      <div
        class="report-block-list-issue-description-text"
        data-testid="test-summary-row-description"
      >
        {{ summary
        }}<span v-if="popoverOptions" class="text-nowrap"
          >&nbsp;<popover v-if="popoverOptions" :options="popoverOptions" class="align-top" />
        </span>
      </div>
    </div>
    <div
      v-if="$slots.default"
      class="text-right flex-fill d-flex justify-content-end flex-column flex-sm-row"
    >
      <slot></slot>
    </div>
  </div>
</template>
