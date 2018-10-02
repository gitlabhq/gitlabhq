<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import ReportSection from '~/reports/components/report_section.vue';
import Icon from '~/vue_shared/components/icon.vue';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import SetLicenseApprovalModal from 'ee/vue_shared/license_management/components/set_approval_status_modal.vue';
import { componentNames } from 'ee/vue_shared/components/reports/issue_body';

import createStore from './store';

const store = createStore();

export default {
  name: 'MrWidgetLicenses',
  componentNames,
  store,
  components: {
    ReportSection,
    SetLicenseApprovalModal,
    Icon,
  },
  mixins: [reportsMixin],
  props: {
    headPath: {
      type: String,
      required: true,
    },
    basePath: {
      type: String,
      required: false,
      default: null,
    },
    fullReportPath: {
      type: String,
      required: false,
      default: null,
    },
    licenseManagementSettingsPath: {
      type: String,
      required: false,
      default: null,
    },
    apiUrl: {
      type: String,
      required: true,
    },
    canManageLicenses: {
      type: Boolean,
      required: true,
    },
    reportSectionClass: {
      type: String,
      required: false,
      default: '',
    },
    alwaysOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['loadLicenseReportError']),
    ...mapGetters(['licenseReport', 'isLoading', 'licenseSummaryText']),
    hasLicenseReportIssues() {
      const { licenseReport } = this;
      return licenseReport && licenseReport.length > 0;
    },
    licenseReportStatus() {
      return this.checkReportStatus(this.isLoading, this.loadLicenseReportError);
    },
    showActionButtons() {
      return this.licenseManagementSettingsPath !== null || this.fullReportPath !== null;
    },
  },
  watch: {
    licenseReport() {
      this.$emit('updateBadgeCount', this.licenseReport.length);
    },
  },
  mounted() {
    const { headPath, basePath, apiUrl, canManageLicenses } = this;

    this.setAPISettings({
      apiUrlManageLicenses: apiUrl,
      headPath,
      basePath,
      canManageLicenses,
    });

    this.loadLicenseReport();
    this.loadManagedLicenses();
  },
  methods: {
    ...mapActions(['setAPISettings', 'loadManagedLicenses', 'loadLicenseReport']),
  },
};
</script>
<template>
  <div>
    <set-license-approval-modal/>
    <report-section
      :status="licenseReportStatus"
      :success-text="licenseSummaryText"
      :loading-text="licenseSummaryText"
      :error-text="licenseSummaryText"
      :neutral-issues="licenseReport"
      :has-issues="hasLicenseReportIssues"
      :component="$options.componentNames.LicenseIssueBody"
      :class="reportSectionClass"
      :always-open="alwaysOpen"
      class="license-report-widget mr-report"
    >
      <div
        v-if="showActionButtons"
        slot="actionButtons"
        class="append-right-default"
      >
        <a
          v-if="licenseManagementSettingsPath"
          :class="{'append-right-8': fullReportPath}"
          :href="licenseManagementSettingsPath"
          class="btn btn-default btn-sm js-manage-licenses"
        >
          {{ s__("ciReport|Manage licenses") }}
        </a>
        <a
          v-if="fullReportPath"
          :href="fullReportPath"
          target="_blank"
          class="btn btn-default btn-sm js-full-report"
        >
          {{ s__("ciReport|View full report") }}
          <icon
            :size="16"
            name="external-link"
          />
        </a>
      </div>
    </report-section>
  </div>
</template>
