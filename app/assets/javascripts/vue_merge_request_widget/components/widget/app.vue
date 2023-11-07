<script>
export default {
  components: {
    MrSecurityWidget: () =>
      import(
        '~/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue'
      ),
    MrTestReportWidget: () => import('~/vue_merge_request_widget/extensions/test_report/index.vue'),
    MrTerraformWidget: () => import('~/vue_merge_request_widget/extensions/terraform/index.vue'),
    MrCodeQualityWidget: () =>
      import('~/vue_merge_request_widget/extensions/code_quality/index.vue'),
    MrAccessibilityWidget: () =>
      import('~/vue_merge_request_widget/extensions/accessibility/index.vue'),
  },

  props: {
    mr: {
      type: Object,
      required: true,
    },
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
  },
};
</script>

<template>
  <section
    v-if="widgets.length"
    role="region"
    :aria-label="__('Merge request reports')"
    data-testid="mr-widget-app"
    class="mr-widget-section"
  >
    <component
      :is="widget"
      v-for="(widget, index) in widgets"
      :key="widget.name || index"
      :mr="mr"
      class="mr-widget-section"
    />
  </section>
</template>
