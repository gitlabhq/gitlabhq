<script>
import Vue from 'vue';
import { uniqueId } from 'lodash';
import {
  GlAlert,
  GlIcon,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlLink,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
  GlSprintf,
  GlLoadingIcon,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/wrapper';
import { s__, __, n__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import { VARIABLE_TYPE, FILE_TYPE, CONFIG_VARIABLES_TIMEOUT } from '../constants';
import { backOff } from '~/lib/utils/common_utils';
import httpStatusCodes from '~/lib/utils/http_status';

export default {
  typeOptions: [
    { value: VARIABLE_TYPE, text: __('Variable') },
    { value: FILE_TYPE, text: __('File') },
  ],
  variablesDescription: s__(
    'Pipeline|Specify variable values to be used in this run. The values specified in %{linkStart}CI/CD settings%{linkEnd} will be used by default.',
  ),
  formElementClasses: 'gl-mr-3 gl-mb-3 gl-flex-basis-quarter gl-flex-shrink-0 gl-flex-grow-0',
  errorTitle: __('Pipeline cannot be run.'),
  warningTitle: __('The form contains the following warning:'),
  maxWarningsSummary: __('%{total} warnings found: showing first %{warningsDisplayed}'),
  components: {
    GlAlert,
    GlIcon,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlLink,
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
    GlSprintf,
    GlLoadingIcon,
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
    branches: {
      type: Array,
      required: true,
    },
    tags: {
      type: Array,
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
      searchTerm: '',
      refValue: {
        shortName: this.refParam,
      },
      form: {},
      error: null,
      warnings: [],
      totalWarnings: 0,
      isWarningDismissed: false,
      isLoading: false,
    };
  },
  computed: {
    lowerCasedSearchTerm() {
      return this.searchTerm.toLowerCase();
    },
    filteredBranches() {
      return this.branches.filter((branch) =>
        branch.shortName.toLowerCase().includes(this.lowerCasedSearchTerm),
      );
    },
    filteredTags() {
      return this.tags.filter((tag) =>
        tag.shortName.toLowerCase().includes(this.lowerCasedSearchTerm),
      );
    },
    hasTags() {
      return this.tags.length > 0;
    },
    overMaxWarningsLimit() {
      return this.totalWarnings > this.maxWarnings;
    },
    warningsSummary() {
      return n__('%d warning found:', '%d warnings found:', this.warnings.length);
    },
    summaryMessage() {
      return this.overMaxWarningsLimit ? this.$options.maxWarningsSummary : this.warningsSummary;
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
  },
  created() {
    // this is needed until we add support for ref type in url query strings
    // ensure default branch is called with full ref on load
    // https://gitlab.com/gitlab-org/gitlab/-/issues/287815
    if (this.refValue.shortName === this.defaultBranch) {
      this.refValue.fullName = `refs/heads/${this.refValue.shortName}`;
    }

    this.setRefSelected(this.refValue);
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
    setRefSelected(refValue) {
      this.refValue = refValue;

      if (!this.form[this.refFullName]) {
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
      }
    },
    isSelected(ref) {
      return ref.fullName === this.refValue.fullName;
    },
    removeVariable(index) {
      this.variables.splice(index, 1);
    },
    canRemove(index) {
      return index < this.variables.length - 1;
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
      const filteredVariables = this.variables
        .filter(({ key, value }) => key !== '' && value !== '')
        .map(({ variable_type, key, value }) => ({
          variable_type,
          key,
          secret_value: value,
        }));

      return axios
        .post(this.pipelinesPath, {
          // send shortName as fall back for query params
          // https://gitlab.com/gitlab-org/gitlab/-/issues/287815
          ref: this.refValue.fullName || this.refShortName,
          variables_attributes: filteredVariables,
        })
        .then(({ data }) => {
          redirectTo(`${this.pipelinesPath}/${data.id}`);
        })
        .catch((err) => {
          const { errors, warnings, total_warnings: totalWarnings } = err.response.data;
          const [error] = errors;
          this.error = error;
          this.warnings = warnings;
          this.totalWarnings = totalWarnings;
        });
    },
  },
};
</script>

<template>
  <gl-form @submit.prevent="createPipeline">
    <gl-alert
      v-if="error"
      :title="$options.errorTitle"
      :dismissible="false"
      variant="danger"
      class="gl-mb-4"
      data-testid="run-pipeline-error-alert"
    >
      <span v-safe-html="error"></span>
    </gl-alert>
    <gl-alert
      v-if="shouldShowWarning"
      :title="$options.warningTitle"
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
      <gl-dropdown :text="refShortName" block>
        <gl-search-box-by-type v-model.trim="searchTerm" :placeholder="__('Search refs')" />
        <gl-dropdown-section-header>{{ __('Branches') }}</gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="branch in filteredBranches"
          :key="branch.fullName"
          class="gl-font-monospace"
          is-check-item
          :is-checked="isSelected(branch)"
          @click="setRefSelected(branch)"
        >
          {{ branch.shortName }}
        </gl-dropdown-item>
        <gl-dropdown-section-header v-if="hasTags">{{ __('Tags') }}</gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="tag in filteredTags"
          :key="tag.fullName"
          class="gl-font-monospace"
          is-check-item
          :is-checked="isSelected(tag)"
          @click="setRefSelected(tag)"
        >
          {{ tag.shortName }}
        </gl-dropdown-item>
      </gl-dropdown>
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
          />
          <gl-form-input
            v-model="variable.key"
            :placeholder="s__('CiVariables|Input variable key')"
            :class="$options.formElementClasses"
            data-testid="pipeline-form-ci-variable-key"
            @change="addEmptyVariable(refFullName)"
          />
          <gl-form-input
            v-model="variable.value"
            :placeholder="s__('CiVariables|Input variable value')"
            class="gl-mb-3"
            data-testid="pipeline-form-ci-variable-value"
          />

          <template v-if="variables.length > 1">
            <gl-button
              v-if="canRemove(index)"
              class="gl-md-ml-3 gl-mb-3"
              data-testid="remove-ci-variable-row"
              variant="danger"
              category="secondary"
              @click="removeVariable(index)"
            >
              <gl-icon class="gl-mr-0! gl-display-none gl-md-display-block" name="clear" />
              <span class="gl-md-display-none">{{ s__('CiVariables|Remove variable') }}</span>
            </gl-button>
            <gl-button
              v-else
              class="gl-md-ml-3 gl-mb-3 gl-display-none gl-md-display-block gl-visibility-hidden"
              icon="clear"
            />
          </template>
        </div>
        <div v-if="descriptions[variable.key]" class="gl-text-gray-500 gl-mb-3">
          {{ descriptions[variable.key] }}
        </div>
      </div>

      <template #description
        ><gl-sprintf :message="$options.variablesDescription">
          <template #link="{ content }">
            <gl-link :href="settingsLink">{{ content }}</gl-link>
          </template>
        </gl-sprintf></template
      >
    </gl-form-group>
    <div
      class="gl-border-t-solid gl-border-gray-100 gl-border-t-1 gl-p-5 gl-bg-gray-10 gl-display-flex gl-justify-content-space-between"
    >
      <gl-button
        type="submit"
        category="primary"
        variant="success"
        class="js-no-auto-disable"
        data-qa-selector="run_pipeline_button"
        >{{ s__('Pipeline|Run Pipeline') }}</gl-button
      >
      <gl-button :href="pipelinesPath">{{ __('Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
