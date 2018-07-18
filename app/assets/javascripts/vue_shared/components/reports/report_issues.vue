<script>
import Icon from '~/vue_shared/components/icon.vue';

<<<<<<< HEAD
import PerformanceIssue from 'ee/vue_merge_request_widget/components/performance_issue_body.vue';
import CodequalityIssue from 'ee/vue_merge_request_widget/components/codequality_issue_body.vue';
import LicenseIssue from 'ee/vue_merge_request_widget/components/license_issue_body.vue';
import SastIssue from 'ee/vue_shared/security_reports/components/sast_issue_body.vue';
import SastContainerIssue from 'ee/vue_shared/security_reports/components/sast_container_issue_body.vue';
import DastIssue from 'ee/vue_shared/security_reports/components/dast_issue_body.vue';
import { SAST, DAST, SAST_CONTAINER } from 'ee/vue_shared/security_reports/store/constants';

=======
>>>>>>> upstream/master
export default {
  name: 'ReportIssues',
  components: {
    Icon,
<<<<<<< HEAD
    SastIssue,
    SastContainerIssue,
    DastIssue,
    PerformanceIssue,
    CodequalityIssue,
    LicenseIssue,
=======
>>>>>>> upstream/master
  },
  props: {
    issues: {
      type: Array,
      required: true,
    },
<<<<<<< HEAD
    // security || codequality || performance || docker || dast || license
=======
>>>>>>> upstream/master
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
<<<<<<< HEAD
    isTypeCodequality() {
      return this.type === 'codequality';
    },
    isTypePerformance() {
      return this.type === 'performance';
    },
    isTypeLicense() {
      return this.type === 'license';
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
=======
>>>>>>> upstream/master
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
<<<<<<< HEAD
            v-if="isTypeLicense"
            :size="24"
            name="status_created_borderless"
            css-classes="prepend-left-4"
          />
          <icon
            v-else
=======
>>>>>>> upstream/master
            :name="iconName"
            :size="32"
          />
        </div>

<<<<<<< HEAD
        <sast-issue
          v-if="isTypeSast"
          :issue="issue"
          :status="status"
        />

        <dast-issue
          v-else-if="isTypeDast"
          :issue="issue"
          :issue-index="index"
          :status="status"
        />

        <sast-container-issue
          v-else-if="isTypeSastContainer"
          :issue="issue"
          :status="status"
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

        <license-issue
          v-else-if="isTypeLicense"
          :issue="issue"
        />
=======
>>>>>>> upstream/master
      </li>
    </ul>
  </div>
</template>
