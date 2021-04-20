<script>
import { GlAlert, GlLink, GlSprintf, GlTable } from '@gitlab/ui';
import { __ } from '~/locale';
import CiLintResultsParam from './ci_lint_results_param.vue';
import CiLintResultsValue from './ci_lint_results_value.vue';
import CiLintWarnings from './ci_lint_warnings.vue';

const thBorderColor = 'gl-border-gray-100!';

export default {
  correct: {
    variant: 'success',
    text: __('Syntax is correct.'),
  },
  incorrect: {
    variant: 'danger',
    text: __('Syntax is incorrect.'),
  },
  includesText: __(
    'CI configuration validated, including all configuration added with the %{codeStart}includes%{codeEnd} keyword. %{link}',
  ),
  warningTitle: __('The form contains the following warning:'),
  fields: [
    {
      key: 'parameter',
      label: __('Parameter'),
      thClass: thBorderColor,
    },
    {
      key: 'value',
      label: __('Value'),
      thClass: thBorderColor,
    },
  ],
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    GlTable,
    CiLintWarnings,
    CiLintResultsValue,
    CiLintResultsParam,
  },
  props: {
    errors: {
      type: Array,
      required: false,
      default: () => [],
    },
    dryRun: {
      type: Boolean,
      required: false,
      default: false,
    },
    isValid: {
      type: Boolean,
      required: true,
    },
    jobs: {
      type: Array,
      required: false,
      default: () => [],
    },
    lintHelpPagePath: {
      type: String,
      required: true,
    },
    warnings: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      isWarningDismissed: false,
    };
  },
  computed: {
    status() {
      return this.isValid ? this.$options.correct : this.$options.incorrect;
    },
    shouldShowTable() {
      return this.errors.length === 0;
    },
    shouldShowError() {
      return this.errors.length > 0;
    },
    shouldShowWarning() {
      return this.warnings.length > 0 && !this.isWarningDismissed;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      class="gl-mb-5"
      :variant="status.variant"
      :title="__('Status:')"
      :dismissible="false"
      data-testid="ci-lint-status"
      >{{ status.text }}
      <gl-sprintf :message="$options.includesText">
        <template #code="{ content }">
          <code>
            {{ content }}
          </code>
        </template>
        <template #link>
          <gl-link :href="lintHelpPagePath" target="_blank">
            {{ __('More information') }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <pre
      v-if="shouldShowError"
      class="gl-mb-5"
      data-testid="ci-lint-errors"
    ><div v-for="error in errors" :key="error">{{ error }}</div></pre>

    <ci-lint-warnings
      v-if="shouldShowWarning"
      :warnings="warnings"
      data-testid="ci-lint-warnings"
      @dismiss="isWarningDismissed = true"
    />

    <gl-table
      v-if="shouldShowTable"
      :items="jobs"
      :fields="$options.fields"
      bordered
      data-testid="ci-lint-table"
    >
      <template #cell(parameter)="{ item }">
        <ci-lint-results-param :stage="item.stage" :job-name="item.name" />
      </template>
      <template #cell(value)="{ item }">
        <ci-lint-results-value :item="item" :dry-run="dryRun" />
      </template>
    </gl-table>
  </div>
</template>
