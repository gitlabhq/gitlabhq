<script>
import { mapActions, mapState } from 'vuex';
import { s__, sprintf, n__ } from '~/locale';
import createFlash from '~/flash';
import ReportSection from '~/vue_shared/components/reports/report_section.vue';
import { componentNames } from 'ee/vue_shared/components/reports/issue_body';
import IssueModal from './components/modal.vue';
import mixin from './mixins/security_report_mixin';
import reportsMixin from './mixins/reports_mixin';

export default {
  components: {
    ReportSection,
    IssueModal,
  },
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
    ...mapState(['sast', 'dependencyScanning', 'sastContainer', 'dast']),

    sastText() {
      return this.summaryTextBuilder('SAST', this.sast.newIssues.length);
    },

    dependencyScanningText() {
      return this.summaryTextBuilder(
        'Dependency scanning',
        this.dependencyScanning.newIssues.length,
      );
    },

    sastContainerText() {
      return this.summaryTextBuilder('Container scanning', this.sastContainer.newIssues.length);
    },

    dastText() {
      return this.summaryTextBuilder('DAST', this.dast.newIssues.length);
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

      this.fetchSastReports()
        .then(() => {
          this.$emit('updateBadgeCount', this.sast.newIssues.length);
        })
        .catch(() => createFlash(s__('ciReport|There was an error loading SAST report')));
    }

    if (this.dependencyScanningHeadPath) {
      this.setDependencyScanningHeadPath(this.dependencyScanningHeadPath);

      this.fetchDependencyScanningReports()
        .then(() => {
          this.$emit('updateBadgeCount', this.dependencyScanning.newIssues.length);
        })
        .catch(() =>
          createFlash(s__('ciReport|There was an error loading dependency scanning report')),
        );
    }

    if (this.sastContainerHeadPath) {
      this.setSastContainerHeadPath(this.sastContainerHeadPath);

      this.fetchSastContainerReports()
      .then(() => {
        this.$emit('updateBadgeCount', this.sastContainer.newIssues.length);
      })
      .catch(() =>
        createFlash(s__('ciReport|There was an error loading container scanning report')),
      );
    }

    if (this.dastHeadPath) {
      this.setDastHeadPath(this.dastHeadPath);

      this.fetchDastReports()
      .then(() => {
        this.$emit('updateBadgeCount', this.dast.newIssues.length);
      })
      .catch(() =>
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
    ]),

    summaryTextBuilder(type, issuesCount = 0) {
      if (issuesCount === 0) {
        return sprintf(s__('ciReport|%{type} detected no vulnerabilities'), {
          type,
        });
      }
      return sprintf(
        n__('%{type} detected 1 vulnerability', '%{type} detected %{vulnerabilityCount} vulnerabilities', issuesCount),
        { type, vulnerabilityCount: issuesCount },
      );
    },
    translateText(type) {
      return {
        error: sprintf(s__('ciReport|%{reportName} resulted in error while loading results'), {
          reportName: type,
        }),
        loading: sprintf(s__('ciReport|%{reportName} is loading'), {
          reportName: type,
        }),
      };
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
      :loading-text="translateText('SAST').loading"
      :error-text="translateText('SAST').error"
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
      :loading-text="translateText('Dependency scanning').loading"
      :error-text="translateText('Dependency scanning').error"
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
      :loading-text="translateText('Container scanning').loading"
      :error-text="translateText('Container scanning').error"
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
      :loading-text="translateText('DAST').loading"
      :error-text="translateText('DAST').error"
      :success-text="dastText"
      :unresolved-issues="dast.newIssues"
      :has-issues="dast.newIssues.length > 0"
      :popover-options="dastPopover"
      class="js-dast-widget split-report-section"
    />

    <issue-modal />
  </div>
</template>
