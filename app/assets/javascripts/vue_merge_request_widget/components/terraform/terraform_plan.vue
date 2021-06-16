<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'TerraformPlan',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    plan: {
      required: true,
      type: Object,
    },
  },
  i18n: {
    changes: s__(
      'Terraform|Reported Resource Changes: %{addNum} to add, %{changeNum} to change, %{deleteNum} to delete',
    ),
    generationErrored: s__('Terraform|Generating the report caused an error.'),
    namedReportFailed: s__('Terraform|The report %{name} failed to generate.'),
    namedReportGenerated: s__('Terraform|The report %{name} was generated in your pipelines.'),
    reportFailed: s__('Terraform|A report failed to generate.'),
    reportGenerated: s__('Terraform|A report was generated in your pipelines.'),
  },
  computed: {
    addNum() {
      return Number(this.plan.create);
    },
    changeNum() {
      return Number(this.plan.update);
    },
    deleteNum() {
      return Number(this.plan.delete);
    },
    iconType() {
      return this.validPlanValues ? 'doc-changes' : 'warning';
    },
    reportChangeText() {
      if (this.validPlanValues) {
        return this.$options.i18n.changes;
      }

      return this.$options.i18n.generationErrored;
    },
    reportHeaderText() {
      if (this.validPlanValues) {
        return this.plan.job_name
          ? this.$options.i18n.namedReportGenerated
          : this.$options.i18n.reportGenerated;
      }

      return this.plan.job_name
        ? this.$options.i18n.namedReportFailed
        : this.$options.i18n.reportFailed;
    },
    validPlanValues() {
      return this.addNum + this.changeNum + this.deleteNum >= 0;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-pb-3">
    <span
      class="gl-display-flex gl-align-items-center gl-justify-content-center gl-align-self-start gl-px-2"
    >
      <gl-icon :name="iconType" :size="16" data-testid="change-type-icon" />
    </span>

    <div class="gl-display-flex gl-flex-grow-1 gl-flex-direction-column flex-md-row gl-pl-3">
      <div class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-pr-3">
        <p class="gl-mb-3 gl-line-height-normal">
          <gl-sprintf :message="reportHeaderText">
            <template #name>
              <strong>{{ plan.job_name }}</strong>
            </template>
          </gl-sprintf>
        </p>

        <p class="gl-mb-3 gl-line-height-normal">
          <gl-sprintf :message="reportChangeText">
            <template #addNum>
              <strong>{{ addNum }}</strong>
            </template>

            <template #changeNum>
              <strong>{{ changeNum }}</strong>
            </template>

            <template #deleteNum>
              <strong>{{ deleteNum }}</strong>
            </template>
          </gl-sprintf>
        </p>
      </div>

      <div>
        <gl-link
          v-if="plan.job_path"
          :href="plan.job_path"
          target="_blank"
          data-testid="terraform-report-link"
          data-track-event="click_terraform_mr_plan_button"
          data-track-label="mr_widget_terraform_mr_plan_button"
          data-track-property="terraform_mr_plan_button"
          class="btn btn-sm"
          rel="noopener"
        >
          {{ __('View full log') }}
          <gl-icon name="external-link" />
        </gl-link>
      </div>
    </div>
  </div>
</template>
