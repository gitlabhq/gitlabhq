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
        return s__(
          'Terraform|Reported Resource Changes: %{addNum} to add, %{changeNum} to change, %{deleteNum} to delete',
        );
      }

      return s__('Terraform|Generating the report caused an error.');
    },
    reportHeaderText() {
      if (this.validPlanValues) {
        return this.plan.job_name
          ? s__('Terraform|The Terraform report %{name} was generated in your pipelines.')
          : s__('Terraform|A Terraform report was generated in your pipelines.');
      }

      return this.plan.job_name
        ? s__('Terraform|The Terraform report %{name} failed to generate.')
        : s__('Terraform|A Terraform report failed to generate.');
    },
    validPlanValues() {
      return this.addNum + this.changeNum + this.deleteNum >= 0;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex">
    <span
      class="gl-display-flex gl-align-items-center gl-justify-content-center gl-mr-3 gl-align-self-start gl-mt-1"
    >
      <gl-icon :name="iconType" :size="18" data-testid="change-type-icon" />
    </span>

    <div class="gl-display-flex gl-flex-fill-1 gl-flex-direction-column flex-md-row">
      <div class="gl-flex-fill-1 gl-display-flex gl-flex-direction-column">
        <p class="gl-m-0 gl-pr-1">
          <gl-sprintf :message="reportHeaderText">
            <template #name>
              <strong>{{ plan.job_name }}</strong>
            </template>
          </gl-sprintf>
        </p>

        <p class="gl-m-0">
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
