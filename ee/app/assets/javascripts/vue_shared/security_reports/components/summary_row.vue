<script>
import Icon from '~/vue_shared/components/icon.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import popover from '~/vue_shared/directives/popover';

/**
 * Renders the summary row for each security report
 */

export default {
  name: 'SecuritySummaryRow',
  components: {
    Icon,
    CiIcon,
  },
  directives: {
    popover,
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
    popoverTitle: {
      type: String,
      required: true,
    },
    popoverContent: {
      type: String,
      required: true,
    },
  },
  computed: {
    popoverOptions() {
      return {
        html: true,
        trigger: 'focus',
        placement: 'top',
        title: this.popoverTitle,
        content: this.popoverContent,
        template: '<div class="popover" role="tooltip"><div class="arrow"></div><p class="popover-title"></p><div class="popover-content"></div></div>',
      };
    },
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
  <div class="report-block-list-issue">
    <div class="report-block-list-icon append-right-10 prepend-left-10">
      <ci-icon :status="iconStatus" />
    </div>

    <div class="report-block-list-issue-description">
      <div class="report-block-list-issue-description-text append-right-5">
        {{ summary }}
      </div>

      <button
        type="button"
        class="btn-transparent btn-blank"
        v-popover="popoverOptions"
        tabindex="0"
      >
        <icon name="question" />
      </button>
    </div>
  </div>
</template>
