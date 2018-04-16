<script>
  import { mapActions, mapState, mapGetters } from 'vuex';
  import { SAST, DAST, SAST_CONTAINER } from './store/constants';
  import store from './store';
  import ReportSection from './components/report_section.vue';
  import SummaryRow from './components/summary_row.vue';
  import IssuesList from './components/issues_list.vue';
  import securityReportsMixin from './mixins/security_report_mixin';

  export default {
    store,
    components: {
      ReportSection,
      SummaryRow,
      IssuesList,
    },
    mixins: [securityReportsMixin],
    props: {
      headBlobPath: {
        type: String,
        required: true,
      },
      baseBlobPath: {
        type: String,
        required: false,
        default: null,
      },
      sastHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      sastBasePath: {
        type: String,
        required: false,
        default: null,
      },
      dastHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      dastBasePath: {
        type: String,
        required: false,
        default: null,
      },
      sastContainerHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      sastContainerBasePath: {
        type: String,
        required: false,
        default: null,
      },
      dependencyScanningHeadPath: {
        type: String,
        required: false,
        default: null,
      },
      dependencyScanningBasePath: {
        type: String,
        required: false,
        default: null,
      },
      sastHelpPath: {
        type: String,
        required: false,
        default: '',
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
        default: '',
      },
    },
    sast: SAST,
    dast: DAST,
    sastContainer: SAST_CONTAINER,
    computed: {
      ...mapState(['sast', 'sastContainer', 'dast', 'dependencyScanning', 'summaryCounts']),
      ...mapGetters([
        'groupedSastText',
        'groupedSummaryText',
        'summaryStatus',
        'groupedSastContainerText',
        'groupedDastText',
        'groupedDependencyText',
        'sastStatusIcon',
        'sastContainerStatusIcon',
        'dastStatusIcon',
        'dependencyScanningStatusIcon',
      ]),
    },

    created() {
      this.setHeadBlobPath(this.headBlobPath);
      this.setBaseBlobPath(this.baseBlobPath);

      if (this.sastHeadPath) {
        this.setSastHeadPath(this.sastHeadPath);

        if (this.sastBasePath) {
          this.setSastBasePath(this.sastBasePath);
        }
        this.fetchSastReports();
      }

      if (this.sastContainerHeadPath) {
        this.setSastContainerHeadPath(this.sastContainerHeadPath);

        if (this.sastContainerBasePath) {
          this.setSastContainerBasePath(this.sastContainerBasePath);
        }
        this.fetchSastContainerReports();
      }

      if (this.dastHeadPath) {
        this.setDastHeadPath(this.dastHeadPath);

        if (this.dastBasePath) {
          this.setDastBasePath(this.dastBasePath);
        }
        this.fetchDastReports();
      }

      if (this.dependencyScanningHeadPath) {
        this.setDependencyScanningHeadPath(this.dependencyScanningHeadPath);

        if (this.dependencyScanningBasePath) {
          this.setDependencyScanningBasePath(this.dependencyScanningBasePath);
        }
        this.fetchDependencyScanningReports();
      }
    },
    methods: {
      ...mapActions([
        'setAppType',
        'setHeadBlobPath',
        'setBaseBlobPath',
        'setSastHeadPath',
        'setSastBasePath',
        'setSastContainerHeadPath',
        'setSastContainerBasePath',
        'setDastHeadPath',
        'setDastBasePath',
        'setDependencyScanningHeadPath',
        'setDependencyScanningBasePath',
        'fetchSastReports',
        'fetchSastContainerReports',
        'fetchDastReports',
        'fetchDependencyScanningReports',
      ]),
    },
  };
</script>
<template>
  <report-section
    class="mr-widget-border-top"
    :status="summaryStatus"
    :success-text="groupedSummaryText"
    :loading-text="groupedSummaryText"
    :error-text="groupedSummaryText"
    :has-issues="true"
  >
    <div
      slot="body"
      class="mr-widget-grouped-section report-block"
    >

      <template v-if="sastHeadPath">
        <summary-row
          class="js-sast-widget"
          :summary="groupedSastText"
          :status-icon="sastStatusIcon"
          :popover-options="sastPopover"
        />

        <issues-list
          class="js-sast-issue-list report-block-group-list"
          v-if="sast.newIssues.length || sast.resolvedIssues.length || sast.allIssues.length"
          :unresolved-issues="sast.newIssues"
          :resolved-issues="sast.resolvedIssues"
          :all-issues="sast.allIssues"
          :type="$options.sast"
        />
      </template>

      <template v-if="dependencyScanningHeadPath">
        <summary-row
          class="js-dependency-scanning-widget"
          :summary="groupedDependencyText"
          :status-icon="dependencyScanningStatusIcon"
          :popover-options="dependencyScanningPopover"
        />

        <issues-list
          class="js-dss-issue-list report-block-group-list"
          v-if="dependencyScanning.newIssues.length ||
          dependencyScanning.resolvedIssues.length || dependencyScanning.allIssues.length"
          :unresolved-issues="dependencyScanning.newIssues"
          :resolved-issues="dependencyScanning.resolvedIssues"
          :all-issues="dependencyScanning.allIssues"
          :type="$options.sast"
        />
      </template>

      <template v-if="sastContainerHeadPath">
        <summary-row
          class="js-sast-container"
          :summary="groupedSastContainerText"
          :status-icon="sastContainerStatusIcon"
          :popover-options="sastContainerPopover"
        />

        <issues-list
          class="report-block-group-list"
          v-if="sastContainer.newIssues.length || sastContainer.resolvedIssues.length"
          :unresolved-issues="sastContainer.newIssues"
          :neutral-issues="sastContainer.resolvedIssues"
          :type="$options.sastContainer"
        />
      </template>

      <template v-if="dastHeadPath">
        <summary-row
          class="js-dast-widget"
          :summary="groupedDastText"
          :status-icon="dastStatusIcon"
          :popover-options="dastPopover"
        />

        <issues-list
          class="report-block-group-list"
          v-if="dast.newIssues.length || dast.resolvedIssues.length"
          :unresolved-issues="dast.newIssues"
          :resolved-issues="dast.resolvedIssues"
          :type="$options.dast"
        />
      </template>
    </div>
  </report-section>
</template>
