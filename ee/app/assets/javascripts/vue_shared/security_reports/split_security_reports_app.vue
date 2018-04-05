<script>
import { mapActions, mapState } from 'vuex';
import { s__, sprintf, n__ } from '~/locale';
import createFlash from '~/flash';
import { SAST } from './store/constants';
import store from './store';
import ReportSection from './components/report_section.vue';
import mixin from './mixins/security_report_mixin';
import reportsMixin from './mixins/reports_mixin';

export default {
  store,
  components: {
    ReportSection,
  },
  mixins: [mixin, reportsMixin],
  props: {
    headBlobPath: {
      type: String,
      required: true,
    },
    sastHeadPath: {
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
    dependencyScanningHelpPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  sast: SAST,
  computed: {
    ...mapState(['sast', 'dependencyScanning']),

    sastText() {
      return this.summaryTextBuilder('SAST', this.sast.newIssues.length);
    },

    dependencyScanningText() {
      return this.summaryTextBuilder(
        'Dependency scanning',
        this.dependencyScanning.newIssues.length,
      );
    },
  },
  created() {
    // update the store with the received props
    this.setHeadBlobPath(this.headBlobPath);

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
  },

  methods: {
    ...mapActions([
      'setHeadBlobPath',
      'setSastHeadPath',
      'setDependencyScanningHeadPath',
      'fetchSastReports',
      'fetchDependencyScanningReports',
    ]),

    summaryTextBuilder(type, issuesCount = 0) {
      if (issuesCount === 0) {
        return sprintf(s__('ciReport|%{type} detected no vulnerabilities'), {
          type,
        });
      }
      return sprintf(
        n__('%{type} detected %d vulnerability', '%{type} detected %d vulnerabilities', issuesCount),
        { type },
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
      class="js-sast-widget split-report-section"
      :type="$options.sast"
      :status="checkReportStatus(sast.isLoading, sast.hasError)"
      :loading-text="translateText('SAST').loading"
      :error-text="translateText('SAST').error"
      :success-text="sastText"
      :unresolved-issues="sast.newIssues"
      :has-issues="sast.newIssues.length > 0"
      :popover-options="sastPopover"
    />

    <report-section
      v-if="dependencyScanningHeadPath"
      class="js-dss-widget split-report-section"
      :type="$options.sast"
      :status="checkReportStatus(dependencyScanning.isLoading, dependencyScanning.hasError)"
      :loading-text="translateText('Dependency scanning').loading"
      :error-text="translateText('Dependency scanning').error"
      :success-text="dependencyScanningText"
      :unresolved-issues="dependencyScanning.newIssues"
      :has-issues="dependencyScanning.newIssues.length > 0"
      :popover-options="dependencyScanningPopover"
    />
  </div>
</template>
