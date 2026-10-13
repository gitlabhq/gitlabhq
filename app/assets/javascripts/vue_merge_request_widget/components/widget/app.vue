<script>
import { defineAsyncComponent } from 'vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import MergeReportsWidget from './merge_reports_widget.vue';

export default {
  name: 'WidgetApp',
  components: {
    MergeReportsWidget,
    MrSecurityWidget: defineAsyncComponent(
      () =>
        import('~/vue_merge_request_widget/widgets/security_reports/mr_widget_security_reports.vue'),
    ),
    MrTestReportWidget: defineAsyncComponent(
      () => import('~/vue_merge_request_widget/widgets/test_report/index.vue'),
    ),
    MrTerraformWidget: defineAsyncComponent(
      () => import('~/vue_merge_request_widget/widgets/terraform/index.vue'),
    ),
    MrCodeQualityWidget: defineAsyncComponent(
      () => import('~/vue_merge_request_widget/widgets/code_quality/index.vue'),
    ),
    MrAccessibilityWidget: defineAsyncComponent(
      () => import('~/vue_merge_request_widget/widgets/accessibility/index.vue'),
    ),
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      emptyWidgets: {},
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
    isGrouped() {
      return Boolean(this.glFeatures.mergeRequestReportsWidgetGroup && this.mr.reportsTabPath);
    },
    hasReportRows() {
      return this.widgets.some((widget) => !this.emptyWidgets[widget]);
    },
  },
  methods: {
    onEmpty(widget, isEmpty) {
      this.emptyWidgets = { ...this.emptyWidgets, [widget]: isEmpty };
    },
  },
};
</script>

<template>
  <section
    v-if="widgets.length"
    v-show="!isGrouped || hasReportRows"
    role="region"
    :aria-label="__('Merge request reports')"
    data-testid="mr-widget-app"
    class="mr-section-container"
  >
    <div data-testid="reports-widgets-container" class="reports-widgets-container">
      <merge-reports-widget v-if="isGrouped" :mr="mr" class="mr-widget-section">
        <template #reports="{ onReportLoaded, isReportVisible }">
          <component
            :is="widget"
            v-for="widget in widgets"
            v-show="isReportVisible(widget)"
            :key="widget"
            :mr="mr"
            :level="2"
            class="first:gl-border-t-0"
            @loaded="(count, status) => onReportLoaded(widget, count, status)"
            @empty="(isEmpty) => onEmpty(widget, isEmpty)"
          />
        </template>
      </merge-reports-widget>
      <component
        :is="widget"
        v-for="(widget, index) in isGrouped ? [] : widgets"
        :key="widget.name || index"
        :mr="mr"
        class="mr-widget-section"
        :class="{ 'gl-border-t gl-border-t-section': index > 0 }"
      />
    </div>
  </section>
</template>
