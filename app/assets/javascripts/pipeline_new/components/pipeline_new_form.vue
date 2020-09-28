<script>
import Vue from 'vue';
import { uniqueId } from 'lodash';
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlLink,
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlSprintf,
} from '@gitlab/ui';
import { s__, __, n__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import { VARIABLE_TYPE, FILE_TYPE } from '../constants';

export default {
  typeOptions: [
    { value: VARIABLE_TYPE, text: __('Variable') },
    { value: FILE_TYPE, text: __('File') },
  ],
  variablesDescription: s__(
    'Pipeline|Specify variable values to be used in this run. The values specified in %{linkStart}CI/CD settings%{linkEnd} will be used by default.',
  ),
  formElementClasses: 'gl-mr-3 gl-mb-3 table-section section-15',
  errorTitle: __('The form contains the following error:'),
  warningTitle: __('The form contains the following warning:'),
  maxWarningsSummary: __('%{total} warnings found: showing first %{warningsDisplayed}'),
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlLink,
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlSprintf,
  },
  props: {
    pipelinesPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    refs: {
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
      refValue: this.refParam,
      variables: {},
      error: null,
      warnings: [],
      totalWarnings: 0,
      isWarningDismissed: false,
    };
  },
  computed: {
    filteredRefs() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.refs.filter(ref => ref.toLowerCase().includes(lowerCasedSearchTerm));
    },
    variablesLength() {
      return Object.keys(this.variables).length;
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
  },
  created() {
    if (this.variableParams) {
      this.setVariableParams(VARIABLE_TYPE, this.variableParams);
    }

    if (this.fileParams) {
      this.setVariableParams(FILE_TYPE, this.fileParams);
    }

    this.addEmptyVariable();
  },
  methods: {
    addEmptyVariable() {
      this.variables[uniqueId('var')] = {
        variable_type: VARIABLE_TYPE,
        key: '',
        value: '',
      };
    },
    setVariableParams(type, paramsObj) {
      Object.entries(paramsObj).forEach(([key, value]) => {
        this.variables[uniqueId('var')] = {
          key,
          value,
          variable_type: type,
        };
      });
    },
    setRefSelected(ref) {
      this.refValue = ref;
    },
    isSelected(ref) {
      return ref === this.refValue;
    },
    insertNewVariable() {
      Vue.set(this.variables, uniqueId('var'), {
        variable_type: VARIABLE_TYPE,
        key: '',
        value: '',
      });
    },
    removeVariable(key) {
      Vue.delete(this.variables, key);
    },

    canRemove(index) {
      return index < this.variablesLength - 1;
    },
    createPipeline() {
      const filteredVariables = Object.values(this.variables).filter(
        ({ key, value }) => key !== '' && value !== '',
      );

      return axios
        .post(this.pipelinesPath, {
          ref: this.refValue,
          variables: filteredVariables,
        })
        .then(({ data }) => {
          redirectTo(`${this.pipelinesPath}/${data.id}`);
        })
        .catch(err => {
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
      >{{ error }}</gl-alert
    >
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
    <gl-form-group :label="s__('Pipeline|Run for')">
      <gl-dropdown :text="refValue" block>
        <gl-search-box-by-type
          v-model.trim="searchTerm"
          :placeholder="__('Search branches and tags')"
          class="gl-p-2"
        />
        <gl-dropdown-item
          v-for="(ref, index) in filteredRefs"
          :key="index"
          class="gl-font-monospace"
          is-check-item
          :is-checked="isSelected(ref)"
          @click="setRefSelected(ref)"
        >
          {{ ref }}
        </gl-dropdown-item>
      </gl-dropdown>

      <template #description>
        <div>
          {{ s__('Pipeline|Existing branch name or tag') }}
        </div></template
      >
    </gl-form-group>

    <gl-form-group :label="s__('Pipeline|Variables')">
      <div
        v-for="(value, key, index) in variables"
        :key="key"
        class="gl-display-flex gl-align-items-center gl-mb-4 gl-pb-2 gl-border-b-solid gl-border-gray-200 gl-border-b-1 gl-flex-direction-column gl-md-flex-direction-row"
        data-testid="ci-variable-row"
      >
        <gl-form-select
          v-model="variables[key].variable_type"
          :class="$options.formElementClasses"
          :options="$options.typeOptions"
        />
        <gl-form-input
          v-model="variables[key].key"
          :placeholder="s__('CiVariables|Input variable key')"
          :class="$options.formElementClasses"
          data-testid="pipeline-form-ci-variable-key"
          @change.once="insertNewVariable()"
        />
        <gl-form-input
          v-model="variables[key].value"
          :placeholder="s__('CiVariables|Input variable value')"
          class="gl-mr-5 gl-mb-3 table-section section-15"
        />
        <gl-button
          v-if="canRemove(index)"
          icon="issue-close"
          class="gl-mb-3"
          data-testid="remove-ci-variable-row"
          @click="removeVariable(key)"
        />
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
        data-qa-selector="run_pipeline_button"
        >{{ s__('Pipeline|Run Pipeline') }}</gl-button
      >
      <gl-button :href="pipelinesPath">{{ __('Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
