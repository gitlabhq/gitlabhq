<script>
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import Popover from './help_popover.vue';

/**
 * Renders the summary row for each security report
 */

export default {
  name: 'SecuritySummaryRow',
  components: {
    CiIcon,
    LoadingIcon,
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
  <div class="report-block-list-issue report-block-list-issue-parent">
    <div class="report-block-list-icon append-right-10 prepend-left-5">
      <loading-icon
        v-if="statusIcon === 'loading'"
        css-class="report-block-list-loading-icon"
      />
      <ci-icon
        v-else
        :status="iconStatus"
      />
    </div>

    <div class="report-block-list-issue-description">
      <div class="report-block-list-issue-description-text append-right-5">
        {{ summary }}
      </div>

      <popover :options="popoverOptions" />
    </div>
  </div>
</template>
