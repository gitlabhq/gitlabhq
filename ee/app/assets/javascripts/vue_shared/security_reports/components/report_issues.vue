<script>
import Icon from '~/vue_shared/components/icon.vue';
import PerformanceIssue from 'ee/vue_merge_request_widget/components/performance_issue_body.vue';
import CodequalityIssue from 'ee/vue_merge_request_widget/components/codequality_issue_body.vue';
import SastIssue from './sast_issue_body.vue';
import SastContainerIssue from './sast_container_issue_body.vue';
import DastIssue from './dast_issue_body.vue';

import { SAST, DAST, SAST_CONTAINER } from '../store/constants';

export default {
  name: 'ReportIssues',
  components: {
    Icon,
    SastIssue,
    SastContainerIssue,
    DastIssue,
    PerformanceIssue,
    CodequalityIssue,
  },
  props: {
    issues: {
      type: Array,
      required: true,
    },
    // security || codequality || performance || docker || dast
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
    isTypeCodequality() {
      return this.type === 'codequality';
    },
    isTypePerformance() {
      return this.type === 'performance';
    },
    isTypeSast() {
      return this.type === SAST;
    },
    isTypeSastContainer() {
      return this.type === SAST_CONTAINER;
    },
    isTypeDast() {
      return this.type === DAST;
    },
  },
};
</script>
<template>
  <div>
    <ul class="report-block-list">
      <li
        class="report-block-list-issue"
        :class="{ 'is-dismissed': issue.isDismissed }"
        v-for="(issue, index) in issues"
        :key="index"
      >
        <div
          class="report-block-list-icon append-right-5"
          :class="{
            failed: isStatusFailed,
            success: isStatusSuccess,
            neutral: isStatusNeutral,
          }"
        >
          <icon
            :name="iconName"
            :size="32"
          />
        </div>

        <sast-issue
          v-if="isTypeSast"
          :issue="issue"
        />

        <dast-issue
          v-else-if="isTypeDast"
          :issue="issue"
          :issue-index="index"
        />

        <sast-container-issue
          v-else-if="isTypeSastContainer"
          :issue="issue"
        />

        <codequality-issue
          v-else-if="isTypeCodequality"
          :is-status-success="isStatusSuccess"
          :issue="issue"
        />

        <performance-issue
          v-else-if="isTypePerformance"
          :issue="issue"
        />
      </li>
    </ul>
  </div>
</template>
