<script>
import {
  GlAlert,
  GlIcon,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlFormTextarea,
  GlLink,
  GlSprintf,
  GlLoadingIcon,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { uniqueId } from 'lodash';
import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import { backOff } from '~/lib/utils/common_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import { redirectTo } from '~/lib/utils/url_utility';
import { s__, __, n__ } from '~/locale';
import {
  VARIABLE_TYPE,
  FILE_TYPE,
  CONFIG_VARIABLES_TIMEOUT,
  CC_VALIDATION_REQUIRED_ERROR,
} from '../constants';
import filterVariables from '../utils/filter_variables';
import RefsDropdown from './refs_dropdown.vue';

const i18n = {
  variablesDescription: s__(
    'Pipeline|Specify variable values to be used in this run. The values specified in %{linkStart}CI/CD settings%{linkEnd} will be used by default.',
  ),
  defaultError: __('Something went wrong on our end. Please try again.'),
  refsLoadingErrorTitle: s__('Pipeline|Branches or tags could not be loaded.'),
  submitErrorTitle: s__('Pipeline|Pipeline cannot be run.'),
  warningTitle: __('The form contains the following warning:'),
  maxWarningsSummary: __('%{total} warnings found: showing first %{warningsDisplayed}'),
  removeVariableLabel: s__('CiVariables|Remove variable'),
};

export default {
  typeOptions: [
    { value: VARIABLE_TYPE, text: __('Variable') },
    { value: FILE_TYPE, text: __('File') },
  ],
  i18n,
  formElementClasses: 'gl-mr-3 gl-mb-3 gl-flex-basis-quarter gl-flex-shrink-0 gl-flex-grow-0',
  // this height value is used inline on the textarea to match the input field height
  // it's used to prevent the overwrite if 'gl-h-7' or 'gl-h-7!' were used
  textAreaStyle: { height: '32px' },
  components: {
    GlAlert,
    GlIcon,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
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
    configVariablesPath: {
      type: String,
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
      },
      form: {},
      errorTitle: null,
      error: null,
      warnings: [],
      totalWarnings: 0,
      isWarningDismissed: false,
      isLoading: false,
      submitted: false,
    };
  },
  computed: {
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
    variables() {
      return this.form[this.refFullName]?.variables ?? [];
    },
    descriptions() {
      return this.form[this.refFullName]?.descriptions ?? {};
    },
    ccRequiredError() {
      return this.error === CC_VALIDATION_REQUIRED_ERROR;
    },
  },
  watch: {
    refValue() {
      this.loadConfigVariablesForm();
    },
  },
  created() {
    // this is needed until we add support for ref type in url query strings
    // ensure default branch is called with full ref on load
    // https://gitlab.com/gitlab-org/gitlab/-/issues/287815
    if (this.refValue.shortName === this.defaultBranch) {
      this.refValue.fullName = `refs/heads/${this.refValue.shortName}`;
    }

    this.loadConfigVariablesForm();
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
    setVariableParams(refValue, type, paramsObj) {
      Object.entries(paramsObj).forEach(([key, value]) => {
        this.setVariable(refValue, type, key, value);
      });
    },
    removeVariable(index) {
      this.variables.splice(index, 1);
    },
    canRemove(index) {
      return index < this.variables.length - 1;
    },
    loadConfigVariablesForm() {
      // Skip when variables already cached in `form`
      if (this.form[this.refFullName]) {
        return;
      }

      this.fetchConfigVariables(this.refFullName || this.refShortName)
        .then(({ descriptions, params }) => {
          Vue.set(this.form, this.refFullName, {
            variables: [],
            descriptions,
          });

          // Add default variables from yml
          this.setVariableParams(this.refFullName, VARIABLE_TYPE, params);
        })
        .catch(() => {
          Vue.set(this.form, this.refFullName, {
            variables: [],
            descriptions: {},
          });
        })
        .finally(() => {
          // Add/update variables, e.g. from query string
          if (this.variableParams) {
            this.setVariableParams(this.refFullName, VARIABLE_TYPE, this.variableParams);
          }
          if (this.fileParams) {
            this.setVariableParams(this.refFullName, FILE_TYPE, this.fileParams);
          }

          // Adds empty var at the end of the form
          this.addEmptyVariable(this.refFullName);
        });
    },
    fetchConfigVariables(refValue) {
      this.isLoading = true;

      return backOff((next, stop) => {
        axios
          .get(this.configVariablesPath, {
            params: {
              sha: refValue,
            },
          })
          .then(({ data, status }) => {
            if (status === httpStatusCodes.NO_CONTENT) {
              next();
            } else {
              this.isLoading = false;
              stop(data);
            }
          })
          .catch((error) => {
            stop(error);
          });
      }, CONFIG_VARIABLES_TIMEOUT)
        .then((data) => {
          const params = {};
          const descriptions = {};

          Object.entries(data).forEach(([key, { value, description }]) => {
            if (description !== null) {
              params[key] = value;
              descriptions[key] = description;
            }
          });

          return { params, descriptions };
        })
        .catch((error) => {
          this.isLoading = false;

          Sentry.captureException(error);

          return { params: {}, descriptions: {} };
        });
    },
    createPipeline() {
      this.submitted = true;

      return axios
        .post(this.pipelinesPath, {
          // send shortName as fall back for query params
          // https://gitlab.com/gitlab-org/gitlab/-/issues/287815
          ref: this.refValue.fullName || this.refShortName,
          variables_attributes: filterVariables(this.variables),
        })
        .then(({ data }) => {
          redirectTo(`${this.pipelinesPath}/${data.id}`);
        })
        .catch((err) => {
          // always re-enable submit button
          this.submitted = false;

          const {
            errors = [],
            warnings = [],
            total_warnings: totalWarnings = 0,
          } = err?.response?.data;
          const [error] = errors;

          this.reportError({
            title: i18n.submitErrorTitle,
            error,
            warnings,
            totalWarnings,
          });
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
  },
};
</script>

<template>
  <gl-form @submit.prevent="createPipeline">
    <cc-validation-required-alert v-if="ccRequiredError" class="gl-pb-5" />
    <gl-alert
      v-else-if="error"
      :title="errorTitle"
      :dismissible="false"
      variant="danger"
      class="gl-mb-4"
      data-testid="run-pipeline-error-alert"
    >
      <span v-safe-html="error"></span>
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
      <refs-dropdown v-model="refValue" @loadingError="onRefsLoadingError" />
    </gl-form-group>

    <gl-loading-icon v-if="isLoading" class="gl-mb-5" size="lg" />

    <gl-form-group v-else :label="s__('Pipeline|Variables')">
      <div
        v-for="(variable, index) in variables"
        :key="variable.uniqueId"
        class="gl-mb-3 gl-ml-n3 gl-pb-2"
        data-testid="ci-variable-row"
      >
        <div
          class="gl-display-flex gl-align-items-stretch gl-flex-direction-column gl-md-flex-direction-row"
        >
          <gl-form-select
            v-model="variable.variable_type"
            :class="$options.formElementClasses"
            :options="$options.typeOptions"
            data-testid="pipeline-form-ci-variable-type"
          />
          <gl-form-input
            v-model="variable.key"
            :placeholder="s__('CiVariables|Input variable key')"
            :class="$options.formElementClasses"
            data-testid="pipeline-form-ci-variable-key"
            @change="addEmptyVariable(refFullName)"
          />
          <gl-form-textarea
            v-model="variable.value"
            :placeholder="s__('CiVariables|Input variable value')"
            class="gl-mb-3"
            :style="$options.textAreaStyle"
            :no-resize="false"
            data-testid="pipeline-form-ci-variable-value"
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
