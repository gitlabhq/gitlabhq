<script>
export default {
  components: {
    MrSecurityWidget: () =>
      import(
        '~/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue'
      ),
    MrTerraformWidget: () => import('~/vue_merge_request_widget/extensions/terraform/index.vue'),
    MrCodeQualityWidget: () =>
      import('~/vue_merge_request_widget/extensions/code_quality/index.vue'),
  },

  props: {
    mr: {
      type: Object,
      required: true,
    },
  },

  computed: {
    terraformPlansWidget() {
      return this.mr.terraformReportsPath && 'MrTerraformWidget';
    },

    codeQualityWidget() {
      return this.mr.codequalityReportsPath ? 'MrCodeQualityWidget' : undefined;
    },

    widgets() {
      return [this.codeQualityWidget, this.terraformPlansWidget, 'MrSecurityWidget'].filter(
        (w) => w,
      );
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
