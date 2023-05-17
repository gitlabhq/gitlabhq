<script>
import {
  GlAlert,
  GlIcon,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlLink,
  GlSprintf,
  GlLoadingIcon,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { uniqueId } from 'lodash';
import Vue from 'vue';
import { fetchPolicies } from '~/lib/graphql';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { s__, __, n__ } from '~/locale';
import {
  CC_VALIDATION_REQUIRED_ERROR,
  CONFIG_VARIABLES_TIMEOUT,
  FILE_TYPE,
  VARIABLE_TYPE,
} from '../constants';
import createPipelineMutation from '../graphql/mutations/create_pipeline.mutation.graphql';
import ciConfigVariablesQuery from '../graphql/queries/ci_config_variables.graphql';
import filterVariables from '../utils/filter_variables';
import RefsDropdown from './refs_dropdown.vue';

let pollTimeout;
export const POLLING_INTERVAL = 2000;
const i18n = {
  variablesDescription: s__(
    'Pipeline|Specify variable values to be used in this run. The variables specified in the configuration file as well as %{linkStart}CI/CD settings%{linkEnd} are used by default.',
  ),
  overrideNoteText: s__(
    'CiVariables|Variables specified here are %{boldStart}expanded%{boldEnd} and not %{boldStart}masked.%{boldEnd}',
  ),
  defaultError: __('Something went wrong on our end. Please try again.'),
  refsLoadingErrorTitle: s__('Pipeline|Branches or tags could not be loaded.'),
  submitErrorTitle: s__('Pipeline|Pipeline cannot be run.'),
  configButtonTitle: s__('Pipelines|Go to the pipeline editor'),
  warningTitle: __('The form contains the following warning:'),
  maxWarningsSummary: __('%{total} warnings found: showing first %{warningsDisplayed}'),
  removeVariableLabel: s__('CiVariables|Remove variable'),
};

export default {
  typeOptions: {
    [VARIABLE_TYPE]: __('Variable'),
    [FILE_TYPE]: __('File'),
  },
  i18n,
  formElementClasses: 'gl-mr-3 gl-mb-3 gl-flex-basis-quarter gl-flex-shrink-0 gl-flex-grow-0',
  // this height value is used inline on the textarea to match the input field height
  // it's used to prevent the overwrite if 'gl-h-7' or 'gl-h-7!' were used
  textAreaStyle: { height: '32px' },
  components: {
    GlAlert,
    GlIcon,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlLink,
    GlSprintf,
    GlLoadingIcon,
    RefsDropdown,
    CcValidationRequiredAlert: () =>
      import('ee_component/billings/components/cc_validation_required_alert.vue'),
  },
  directives: { SafeHtml },
  props: {
    pipelinesPath: {
      type: String,
      required: true,
    },
    pipelinesEditorPath: {
      type: String,
      required: true,
    },
    canViewPipelineEditor: {
      type: Boolean,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    settingsLink: {
      type: String,
      required: true,
    },
    fileParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    projectPath: {
      type: String,
      required: true,
    },
    refParam: {
      type: String,
      required: false,
      default: '',
    },
    variableParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    maxWarnings: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      refValue: {
        shortName: this.refParam,
        // this is needed until we add support for ref type in url query strings
        // ensure default branch is called with full ref on load
        // https://gitlab.com/gitlab-org/gitlab/-/issues/287815
        fullName: this.refParam === this.defaultBranch ? `refs/heads/${this.refParam}` : undefined,
      },
      configVariablesWithDescription: {},
      form: {},
      errorTitle: null,
      error: null,
      predefinedVariables: null,
      warnings: [],
      totalWarnings: 0,
      isWarningDismissed: false,
      submitted: false,
      ccAlertDismissed: false,
    };
  },
  apollo: {
    ciConfigVariables: {
      fetchPolicy: fetchPolicies.NO_CACHE,
      query: ciConfigVariablesQuery,
      // Skip when variables already cached in `form`
      skip() {
        return Object.keys(this.form).includes(this.refFullName);
      },
      variables() {
        return {
          fullPath: this.projectPath,
          ref: this.refQueryParam,
        };
      },
      update({ project }) {
        return project?.ciConfigVariables;
      },
      result({ data }) {
        this.predefinedVariables = data?.project?.ciConfigVariables;

        // API cache is empty when predefinedVariables === null, so we need to
        // poll while cache values are being populated in the backend.
        // After CONFIG_VARIABLES_TIMEOUT ms have passed, we stop polling
        // and populate the form regardless.
        if (this.isFetchingCiConfigVariables && !pollTimeout) {
          pollTimeout = setTimeout(() => {
            this.predefinedVariables = [];
            this.clearPolling();
            this.populateForm();
          }, CONFIG_VARIABLES_TIMEOUT);
        }

        if (!this.isFetchingCiConfigVariables) {
          this.clearPolling();
          this.populateForm();
        }
      },
      error(error) {
        Sentry.captureException(error);
      },
      pollInterval: POLLING_INTERVAL,
    },
  },
  computed: {
    isFetchingCiConfigVariables() {
      return this.predefinedVariables === null;
    },
    isLoading() {
      return this.$apollo.queries.ciConfigVariables.loading || this.isFetchingCiConfigVariables;
    },
    overMaxWarningsLimit() {
      return this.totalWarnings > this.maxWarnings;
    },
    warningsSummary() {
      return n__('%d warning found:', '%d warnings found:', this.warnings.length);
    },
    summaryMessage() {
      return this.overMaxWarningsLimit ? i18n.maxWarningsSummary : this.warningsSummary;
    },
    shouldShowWarning() {
      return this.warnings.length > 0 && !this.isWarningDismissed;
    },
    refShortName() {
      return this.refValue.shortName;
    },
    refFullName() {
      return this.refValue.fullName;
    },
    refQueryParam() {
      return this.refFullName || this.refShortName;
    },
    variables() {
      return this.form[this.refFullName]?.variables ?? [];
    },
    descriptions() {
      return this.form[this.refFullName]?.descriptions ?? {};
    },
    ccRequiredError() {
      return this.error === CC_VALIDATION_REQUIRED_ERROR && !this.ccAlertDismissed;
    },
  },
  methods: {
    addEmptyVariable(refValue) {
      const { variables } = this.form[refValue];

      const lastVar = variables[variables.length - 1];
      if (lastVar?.key === '' && lastVar?.value === '') {
        return;
      }

      variables.push({
        uniqueId: uniqueId(`var-${refValue}`),
        variable_type: VARIABLE_TYPE,
        key: '',
        value: '',
      });
    },
    clearPolling() {
      clearTimeout(pollTimeout);
      this.$apollo.queries.ciConfigVariables.stopPolling();
    },
    populateForm() {
      this.configVariablesWithDescription = this.predefinedVariables.reduce(
        (accumulator, { description, key, value, valueOptions }) => {
          if (description) {
            accumulator.descriptions[key] = description;
            accumulator.values[key] = value;
            accumulator.options[key] = valueOptions;
          }

          return accumulator;
        },
        { descriptions: {}, values: {}, options: {} },
      );

      Vue.set(this.form, this.refFullName, {
        descriptions: this.configVariablesWithDescription.descriptions,
        variables: [],
      });

      // Add default variables from yml
      this.setVariableParams(
        this.refFullName,
        VARIABLE_TYPE,
        this.configVariablesWithDescription.values,
      );

      // Add/update variables, e.g. from query string
      if (this.variableParams) {
        this.setVariableParams(this.refFullName, VARIABLE_TYPE, this.variableParams);
      }

      if (this.fileParams) {
        this.setVariableParams(this.refFullName, FILE_TYPE, this.fileParams);
      }

      // Adds empty var at the end of the form
      this.addEmptyVariable(this.refFullName);
    },
    setVariable(refValue, type, key, value) {
      const { variables } = this.form[refValue];

      const variable = variables.find((v) => v.key === key);
      if (variable) {
        variable.type = type;
        variable.value = value;
      } else {
        variables.push({
          uniqueId: uniqueId(`var-${refValue}`),
          key,
          value,
          variable_type: type,
        });
      }
    },
    setVariableAttribute(key, attribute, value) {
      const { variables } = this.form[this.refFullName];
      const variable = variables.find((v) => v.key === key);
      variable[attribute] = value;
    },
    setVariableParams(refValue, type, paramsObj) {
      Object.entries(paramsObj).forEach(([key, value]) => {
        this.setVariable(refValue, type, key, value);
      });
    },
    shouldShowValuesDropdown(key) {
      return this.configVariablesWithDescription.options[key]?.length > 1;
    },
    removeVariable(index) {
      this.variables.splice(index, 1);
    },
    canRemove(index) {
      return index < this.variables.length - 1;
    },
    async createPipeline() {
      this.submitted = true;
      this.ccAlertDismissed = false;

      const { data } = await this.$apollo.mutate({
        mutation: createPipelineMutation,
        variables: {
          endpoint: this.pipelinesPath,
          // send shortName as fall back for query params
          // https://gitlab.com/gitlab-org/gitlab/-/issues/287815
          ref: this.refQueryParam,
          variablesAttributes: filterVariables(this.variables),
        },
      });

      const { id, errors, totalWarnings, warnings } = data.createPipeline;

      if (id) {
        redirectTo(`${this.pipelinesPath}/${id}`); // eslint-disable-line import/no-deprecated
        return;
      }

      // always re-enable submit button
      this.submitted = false;
      const [error] = errors;

      this.reportError({
        title: i18n.submitErrorTitle,
        error,
        warnings,
        totalWarnings,
      });
    },
    onRefsLoadingError(error) {
      this.reportError({ title: i18n.refsLoadingErrorTitle });

      Sentry.captureException(error);
    },
    reportError({ title = null, error = i18n.defaultError, warnings = [], totalWarnings = 0 }) {
      this.errorTitle = title;
      this.error = error;
      this.warnings = warnings;
      this.totalWarnings = totalWarnings;
    },
    dismissError() {
      this.ccAlertDismissed = true;
      this.error = null;
    },
  },
};
</script>

<template>
  <gl-form @submit.prevent="createPipeline">
    <cc-validation-required-alert v-if="ccRequiredError" class="gl-pb-5" @dismiss="dismissError" />
    <gl-alert
      v-else-if="error"
      :title="errorTitle"
      :dismissible="false"
      variant="danger"
      class="gl-mb-4"
    >
      <span v-safe-html="error" data-testid="run-pipeline-error-alert" class="block"></span>
      <gl-button
        v-if="canViewPipelineEditor"
        class="gl-my-3"
        data-testid="ci-cd-pipeline-configuration"
        variant="confirm"
        :aria-label="$options.i18n.configButtonTitle"
        :href="pipelinesEditorPath"
      >
        {{ $options.i18n.configButtonTitle }}
      </gl-button>
    </gl-alert>
    <gl-alert
      v-if="shouldShowWarning"
      :title="$options.i18n.warningTitle"
      variant="warning"
      class="gl-mb-4"
      data-testid="run-pipeline-warning-alert"
      @dismiss="isWarningDismissed = true"
    >
      <details>
        <summary>
          <gl-sprintf :message="summaryMessage">
            <template #total>
              {{ totalWarnings }}
            </template>
            <template #warningsDisplayed>
              {{ maxWarnings }}
            </template>
          </gl-sprintf>
        </summary>
        <p
          v-for="(warning, index) in warnings"
          :key="`warning-${index}`"
          data-testid="run-pipeline-warning"
        >
          {{ warning }}
        </p>
      </details>
    </gl-alert>
    <gl-form-group :label="s__('Pipeline|Run for branch name or tag')">
      <refs-dropdown
        v-model="refValue"
        :project-id="projectId"
        @loadingError="onRefsLoadingError"
      />
    </gl-form-group>

    <gl-loading-icon v-if="isLoading" class="gl-mb-5" size="lg" />

    <gl-form-group v-else class="gl-mb-3" :label="s__('Pipeline|Variables')">
      <div
        v-for="(variable, index) in variables"
        :key="variable.uniqueId"
        class="gl-mb-3 gl-pb-2"
        data-testid="ci-variable-row"
        data-qa-selector="ci_variable_row_container"
      >
        <div
          class="gl-display-flex gl-align-items-stretch gl-flex-direction-column gl-md-flex-direction-row"
        >
          <gl-dropdown
            :text="$options.typeOptions[variable.variable_type]"
            :class="$options.formElementClasses"
            data-testid="pipeline-form-ci-variable-type"
          >
            <gl-dropdown-item
              v-for="type in Object.keys($options.typeOptions)"
              :key="type"
              @click="setVariableAttribute(variable.key, 'variable_type', type)"
            >
              {{ $options.typeOptions[type] }}
            </gl-dropdown-item>
          </gl-dropdown>
          <gl-form-input
            v-model="variable.key"
            :placeholder="s__('CiVariables|Input variable key')"
            :class="$options.formElementClasses"
            data-testid="pipeline-form-ci-variable-key"
            data-qa-selector="ci_variable_key_field"
            @change="addEmptyVariable(refFullName)"
          />
          <gl-dropdown
            v-if="shouldShowValuesDropdown(variable.key)"
            :text="variable.value"
            :class="$options.formElementClasses"
            class="gl-flex-grow-1 gl-mr-0!"
            data-testid="pipeline-form-ci-variable-value-dropdown"
            data-qa-selector="ci_variable_value_dropdown"
          >
            <gl-dropdown-item
              v-for="option in configVariablesWithDescription.options[variable.key]"
              :key="option"
              data-testid="pipeline-form-ci-variable-value-dropdown-items"
              data-qa-selector="ci_variable_value_dropdown_item"
              @click="setVariableAttribute(variable.key, 'value', option)"
            >
              {{ option }}
            </gl-dropdown-item>
          </gl-dropdown>
          <gl-form-textarea
            v-else
            v-model="variable.value"
            :placeholder="s__('CiVariables|Input variable value')"
            class="gl-mb-3"
            :style="$options.textAreaStyle"
            :no-resize="false"
            data-testid="pipeline-form-ci-variable-value"
            data-qa-selector="ci_variable_value_field"
          />

          <template v-if="variables.length > 1">
            <gl-button
              v-if="canRemove(index)"
              class="gl-md-ml-3 gl-mb-3"
              data-testid="remove-ci-variable-row"
              variant="danger"
              category="secondary"
              :aria-label="$options.i18n.removeVariableLabel"
              @click="removeVariable(index)"
            >
              <gl-icon class="gl-mr-0! gl-display-none gl-md-display-block" name="clear" />
              <span class="gl-md-display-none">{{ $options.i18n.removeVariableLabel }}</span>
            </gl-button>
            <gl-button
              v-else
              class="gl-md-ml-3 gl-mb-3 gl-display-none gl-md-display-block gl-visibility-hidden"
              icon="clear"
              :aria-label="$options.i18n.removeVariableLabel"
            />
          </template>
        </div>
        <div v-if="descriptions[variable.key]" class="gl-text-gray-500 gl-mb-3">
          {{ descriptions[variable.key] }}
        </div>
      </div>

      <template #description
        ><gl-sprintf :message="$options.i18n.variablesDescription">
          <template #link="{ content }">
            <gl-link :href="settingsLink">{{ content }}</gl-link>
          </template>
        </gl-sprintf></template
      >
    </gl-form-group>
    <div class="gl-mb-4 gl-text-gray-500">
      <gl-sprintf :message="$options.i18n.overrideNoteText">
        <template #bold="{ content }">
          <strong>
            {{ content }}
          </strong>
        </template>
      </gl-sprintf>
    </div>
    <div class="gl-pt-5 gl-display-flex">
      <gl-button
        type="submit"
        category="primary"
        variant="confirm"
        class="js-no-auto-disable gl-mr-3"
        data-qa-selector="run_pipeline_button"
        data-testid="run_pipeline_button"
        :disabled="submitted"
        >{{ s__('Pipeline|Run pipeline') }}</gl-button
      >
      <gl-button :href="pipelinesPath">{{ __('Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
