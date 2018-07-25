<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'ReportIssues',
  components: {
    Icon,
  },
  props: {
    issues: {
      type: Array,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
    // failed || success
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    iconName() {
      if (this.isStatusFailed) {
        return 'status_failed_borderless';
      } else if (this.isStatusSuccess) {
        return 'status_success_borderless';
      }

      return 'status_created_borderless';
    },
    isStatusFailed() {
      return this.status === 'failed';
    },
    isStatusSuccess() {
      return this.status === 'success';
    },
    isStatusNeutral() {
      return this.status === 'neutral';
    },
  },
};
</script>
<template>
  <div>
    <ul class="report-block-list">
      <li
        v-for="(issue, index) in issues"
        :class="{ 'is-dismissed': issue.isDismissed }"
        :key="index"
        class="report-block-list-issue"
      >
        <div
          :class="{
            failed: isStatusFailed,
            success: isStatusSuccess,
            neutral: isStatusNeutral,
          }"
          class="report-block-list-icon append-right-5"
        >
          <icon
            :name="iconName"
            :size="32"
          />
        </div>

      </li>
    </ul>
  </div>
</template>
