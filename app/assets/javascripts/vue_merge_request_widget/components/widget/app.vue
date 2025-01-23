<script>
import { GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
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
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      collapsed: this.glFeatures.mrReportsTab,
    };
  },
  computed: {
    testReportWidget() {
      return this.mr.testResultsPath && 'MrTestReportWidget';
    },

    terraformPlansWidget() {
      return this.mr.terraformReportsPath && 'MrTerraformWidget';
    },

    codeQualityWidget() {
      return this.mr.codequalityReportsPath ? 'MrCodeQualityWidget' : undefined;
    },

    accessibilityWidget() {
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
      return null;
    },
    statusIcon() {
      return 'success';
    },
    isLoadingSummary() {
      return false;
    },
  },
};
</script>

<template>
  <section
    v-if="widgets.length"
    role="region"
    :aria-label="__('Merge request reports')"
    data-testid="mr-widget-app"
    class="mr-section-container"
  >
    <state-container
      v-if="glFeatures.mrReportsTab"
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
        'gl-border-t gl-relative gl-border-t-section gl-bg-subtle': glFeatures.mrReportsTab,
      }"
    >
      <component
        :is="widget"
        v-for="(widget, index) in widgets"
        :key="widget.name || index"
        :mr="mr"
        class="mr-widget-section"
        :class="{ 'gl-border-t gl-border-t-section': index > 0 }"
      />
    </div>
  </section>
</template>
