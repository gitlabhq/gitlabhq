<script>
import { GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import StateContainer from '../state_container.vue';

export default {
  components: {
    GlSkeletonLoader,
    GlSprintf,
    StateContainer,
    MrSecurityWidget: () =>
      import('~/vue_merge_request_widget/widgets/security_reports/mr_widget_security_reports.vue'),
    MrTestReportWidget: () => import('~/vue_merge_request_widget/widgets/test_report/index.vue'),
    MrTerraformWidget: () => import('~/vue_merge_request_widget/widgets/terraform/index.vue'),
    MrCodeQualityWidget: () => import('~/vue_merge_request_widget/widgets/code_quality/index.vue'),
    MrAccessibilityWidget: () =>
      import('~/vue_merge_request_widget/widgets/accessibility/index.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
  provide() {
    return {
      reportsTabContent: this.reportsTabContent,
    };
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    reportsTabContent: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      collapsed: this.reportsTabContent ? false : this.glFeatures.mrReportsTab,
      findingsCount: 0,
      loadedCount: 0,
    };
  },
  computed: {
    testReportWidget() {
      if (!this.isViewingReport('test-summary')) return undefined;

      return this.mr.testResultsPath && 'MrTestReportWidget';
    },

    terraformPlansWidget() {
      if (!this.isViewingReport('terraform')) return undefined;

      return this.mr.terraformReportsPath && 'MrTerraformWidget';
    },

    codeQualityWidget() {
      if (!this.isViewingReport('code-quality')) return undefined;

      return this.mr.codequalityReportsPath ? 'MrCodeQualityWidget' : undefined;
    },

    accessibilityWidget() {
      if (!this.isViewingReport('accessibility')) return undefined;

      return this.mr.accessibilityReportPath ? 'MrAccessibilityWidget' : undefined;
    },

    widgets() {
      return [
        this.codeQualityWidget,
        this.testReportWidget,
        this.terraformPlansWidget,
        'MrSecurityWidget',
        this.accessibilityWidget,
      ].filter((w) => w);
    },
    collapsedSummaryText() {
      return n__('%d findings', '%d findings', this.findingsCount);
    },
    statusIcon() {
      if (this.loadedCount < this.widgets.length) return 'loading';

      return 'warning';
    },
    isLoadingSummary() {
      return false;
    },
  },
  mounted() {
    if (this.reportsTabContent && !this.widgets.length) {
      this.$router.push({ path: '/' });
    }
  },
  methods: {
    isViewingReport(reportName) {
      if (!this.reportsTabContent) return true;

      return this.$router.currentRoute.params.report === reportName;
    },
    onLoadedReport(findings) {
      this.findingsCount += findings;
      this.loadedCount += 1;
    },
  },
};
</script>

<template>
  <section
    v-if="widgets.length"
    role="region"
    :aria-label="reportsTabContent ? null : __('Merge request reports')"
    data-testid="mr-widget-app"
    :class="{
      'mr-section-container': !reportsTabContent,
    }"
  >
    <state-container
      v-if="glFeatures.mrReportsTab && !reportsTabContent"
      :status="statusIcon"
      is-collapsible
      collapse-on-desktop
      :collapsed="collapsed"
      :is-loading="isLoadingSummary"
      :expand-details-tooltip="__('Expand merge request reports')"
      :collapse-details-tooltip="__('Collapse merge request reports')"
      @toggle="collapsed = !collapsed"
    >
      <template #loading>
        <gl-skeleton-loader :width="334" :height="24">
          <rect x="0" y="0" width="24" height="24" rx="4" />
          <rect x="32" y="2" width="302" height="20" rx="4" />
        </gl-skeleton-loader>
      </template>
      <template #default>
        <gl-sprintf
          :message="__('%{strongStart}Merge reports (%{reportsCount}):%{strongEnd} %{summaryText}')"
        >
          <template #strong="{ content }">
            <strong>
              <gl-sprintf :message="content">
                <template #reportsCount>{{ widgets.length }}</template>
              </gl-sprintf>
            </strong>
          </template>
          <template #summaryText>&nbsp;{{ collapsedSummaryText }}</template>
        </gl-sprintf>
      </template>
    </state-container>
    <div
      v-show="!collapsed"
      data-testid="reports-widgets-container"
      class="reports-widgets-container"
      :class="{
        'gl-border-t gl-relative gl-border-t-section gl-bg-subtle':
          glFeatures.mrReportsTab && !reportsTabContent,
      }"
    >
      <component
        :is="widget"
        v-for="(widget, index) in widgets"
        :key="widget.name || index"
        :mr="mr"
        class="mr-widget-section"
        :class="{
          'gl-border-t gl-border-t-section': index > 0 && !reportsTabContent,
        }"
        @loaded="onLoadedReport"
      />
    </div>
  </section>
</template>
