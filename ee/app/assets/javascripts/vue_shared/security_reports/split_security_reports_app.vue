<script>
import { mapActions, mapState } from 'vuex';
import { s__, sprintf, n__ } from '~/locale';
import createFlash from '~/flash';
import ReportSection from '~/reports/components/report_section.vue';
import { componentNames } from 'ee/vue_shared/components/reports/issue_body';
import IssueModal from './components/modal.vue';
import mixin from './mixins/security_report_mixin';
import reportsMixin from './mixins/reports_mixin';
import messages from './store/messages';

export default {
  components: {
    ReportSection,
    IssueModal,
  },
  messages,
  mixins: [mixin, reportsMixin],
  props: {
    alwaysOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
    headBlobPath: {
      type: String,
      required: true,
    },
    sastHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    dastHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    sastContainerHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    dependencyScanningHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    sastHelpPath: {
      type: String,
      required: false,
      default: null,
    },
    sastContainerHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    dastHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    dependencyScanningHelpPath: {
      type: String,
      required: false,
      default: null,
    },
    vulnerabilityFeedbackPath: {
      type: String,
      required: false,
      default: '',
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    pipelineId: {
      type: Number,
      required: false,
      default: null,
    },
    canCreateFeedback: {
      type: Boolean,
      required: true,
    },
    canCreateIssue: {
      type: Boolean,
      required: true,
    },
  },
  componentNames,
  computed: {
    ...mapState([
      'sast',
      'dependencyScanning',
      'sastContainer',
      'dast',
      'modal',
      'canCreateIssuePermission',
      'canCreateFeedbackPermission',
    ]),

    sastText() {
      return this.summaryTextBuilder(messages.SAST, this.sast.newIssues.length);
    },

    dependencyScanningText() {
      return this.summaryTextBuilder(
        messages.DEPENDENCY_SCANNING,
        this.dependencyScanning.newIssues.length,
      );
    },

    sastContainerText() {
      return this.summaryTextBuilder(
        messages.CONTAINER_SCANNING,
        this.sastContainer.newIssues.length,
      );
    },

    dastText() {
      return this.summaryTextBuilder(messages.DAST, this.dast.newIssues.length);
    },

    issuesCount() {
      return (
        this.dast.newIssues.length +
        this.dependencyScanning.newIssues.length +
        this.sastContainer.newIssues.length +
        this.sast.newIssues.length
      );
    },
  },
  watch: {
    issuesCount() {
      this.$emit('updateBadgeCount', this.issuesCount);
    },
  },
  created() {
    // update the store with the received props
    this.setHeadBlobPath(this.headBlobPath);
    this.setVulnerabilityFeedbackPath(this.vulnerabilityFeedbackPath);
    this.setVulnerabilityFeedbackHelpPath(this.vulnerabilityFeedbackHelpPath);
    this.setPipelineId(this.pipelineId);
    this.setCanCreateIssuePermission(this.canCreateIssue);
    this.setCanCreateFeedbackPermission(this.canCreateFeedback);

    if (this.sastHeadPath) {
      this.setSastHeadPath(this.sastHeadPath);

      this.fetchSastReports().catch(() =>
        createFlash(s__('ciReport|There was an error loading SAST report')),
      );
    }

    if (this.dependencyScanningHeadPath) {
      this.setDependencyScanningHeadPath(this.dependencyScanningHeadPath);

      this.fetchDependencyScanningReports().catch(() =>
        createFlash(s__('ciReport|There was an error loading dependency scanning report')),
      );
    }

    if (this.sastContainerHeadPath) {
      this.setSastContainerHeadPath(this.sastContainerHeadPath);

      this.fetchSastContainerReports().catch(() =>
        createFlash(s__('ciReport|There was an error loading container scanning report')),
      );
    }

    if (this.dastHeadPath) {
      this.setDastHeadPath(this.dastHeadPath);

      this.fetchDastReports().catch(() =>
        createFlash(s__('ciReport|There was an error loading DAST report')),
      );
    }
  },

  methods: {
    ...mapActions([
      'setHeadBlobPath',
      'setSastHeadPath',
      'setDependencyScanningHeadPath',
      'setSastContainerHeadPath',
      'setDastHeadPath',
      'fetchSastReports',
      'fetchDependencyScanningReports',
      'fetchSastContainerReports',
      'fetchDastReports',
      'setVulnerabilityFeedbackPath',
      'setVulnerabilityFeedbackHelpPath',
      'setPipelineId',
      'setCanCreateIssuePermission',
      'setCanCreateFeedbackPermission',
      'dismissIssue',
      'revertDismissIssue',
      'createNewIssue',
    ]),
    summaryTextBuilder(reportType, issuesCount = 0) {
      if (issuesCount === 0) {
        return sprintf(s__('ciReport|%{reportType} detected no vulnerabilities'), {
          reportType,
        });
      }
      return sprintf(
        n__(
          'ciReport|%{reportType} detected %{vulnerabilityCount} vulnerability',
          'ciReport|%{reportType} detected %{vulnerabilityCount} vulnerabilities',
          issuesCount,
        ),
        { reportType, vulnerabilityCount: issuesCount },
      );
    },
  },
};
</script>
<template>
  <div>
    <report-section
      v-if="sastHeadPath"
      :always-open="alwaysOpen"
      :component="$options.componentNames.SastIssueBody"
      :status="checkReportStatus(sast.isLoading, sast.hasError)"
      :loading-text="$options.messages.SAST_IS_LOADING"
      :error-text="$options.messages.SAST_HAS_ERROR"
      :success-text="sastText"
      :unresolved-issues="sast.newIssues"
      :has-issues="sast.newIssues.length > 0"
      :popover-options="sastPopover"
      class="js-sast-widget split-report-section"
    />

    <report-section
      v-if="dependencyScanningHeadPath"
      :always-open="alwaysOpen"
      :component="$options.componentNames.SastIssueBody"
      :status="checkReportStatus(dependencyScanning.isLoading, dependencyScanning.hasError)"
      :loading-text="$options.messages.DEPENDENCY_SCANNING_IS_LOADING"
      :error-text="$options.messages.DEPENDENCY_SCANNING_HAS_ERROR"
      :success-text="dependencyScanningText"
      :unresolved-issues="dependencyScanning.newIssues"
      :has-issues="dependencyScanning.newIssues.length > 0"
      :popover-options="dependencyScanningPopover"
      class="js-dss-widget split-report-section"
    />

    <report-section
      v-if="sastContainerHeadPath"
      :always-open="alwaysOpen"
      :component="$options.componentNames.SastContainerIssueBody"
      :status="checkReportStatus(sastContainer.isLoading, sastContainer.hasError)"
      :loading-text="$options.messages.CONTAINER_SCANNING_IS_LOADING"
      :error-text="$options.messages.CONTAINER_SCANNING_HAS_ERROR"
      :success-text="sastContainerText"
      :unresolved-issues="sastContainer.newIssues"
      :has-issues="sastContainer.newIssues.length > 0"
      :popover-options="sastContainerPopover"
      class="js-dependency-scanning-widget split-report-section"
    />

    <report-section
      v-if="dastHeadPath"
      :always-open="alwaysOpen"
      :component="$options.componentNames.DastIssueBody"
      :status="checkReportStatus(dast.isLoading, dast.hasError)"
      :loading-text="$options.messages.DAST_IS_LOADING"
      :error-text="$options.messages.DAST_HAS_ERROR"
      :success-text="dastText"
      :unresolved-issues="dast.newIssues"
      :has-issues="dast.newIssues.length > 0"
      :popover-options="dastPopover"
      class="js-dast-widget split-report-section"
    />

    <issue-modal
      :modal="modal"
      :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
      :can-create-issue-permission="canCreateIssuePermission"
      :can-create-feedback-permission="canCreateFeedbackPermission"
      @createNewIssue="createNewIssue"
      @dismissIssue="dismissIssue"
      @revertDismissIssue="revertDismissIssue"
    />
  </div>
</template>
