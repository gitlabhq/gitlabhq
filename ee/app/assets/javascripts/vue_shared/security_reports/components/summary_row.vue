<script>
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Popover from './help_popover.vue';

/**
 * Renders the summary row for each security report
 */

export default {
  name: 'SecuritySummaryRow',
  components: {
    CiIcon,
    Popover,
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
      required: true,
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
  <div class="report-block-list-issue prepend-left-default append-right-default">
    <div class="report-block-list-icon append-right-10 prepend-left-5">
      <ci-icon :status="iconStatus" />
    </div>

    <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
      <div class="report-block-list-issue-description-text append-right-5">
        {{ summary }}
      </div>

      <popover :options="popoverOptions" />
    </div>
  </div>
</template>
