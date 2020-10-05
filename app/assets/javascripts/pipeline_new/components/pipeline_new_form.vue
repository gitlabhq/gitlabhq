<script>
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
  formElementClasses: 'gl-mr-3 gl-mb-3 gl-flex-basis-quarter gl-flex-shrink-0 gl-flex-grow-0',
  errorTitle: __('The form contains the following error:'),
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
      variables: [],
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
    this.addEmptyVariable();

    if (this.variableParams) {
      this.setVariableParams(VARIABLE_TYPE, this.variableParams);
    }

    if (this.fileParams) {
      this.setVariableParams(FILE_TYPE, this.fileParams);
    }
  },
  methods: {
    setVariable(type, key, value) {
      const variable = this.variables.find(v => v.key === key);
      if (variable) {
        variable.type = type;
        variable.value = value;
      } else {
        // insert before the empty variable
        this.variables.splice(this.variables.length - 1, 0, {
          uniqueId: uniqueId('var'),
          key,
          value,
          variable_type: type,
        });
      }
    },
    setVariableParams(type, paramsObj) {
      Object.entries(paramsObj).forEach(([key, value]) => {
        this.setVariable(type, key, value);
      });
    },
    setRefSelected(ref) {
      this.refValue = ref;
    },
    isSelected(ref) {
      return ref === this.refValue;
    },
    addEmptyVariable() {
      this.variables.push({
        uniqueId: uniqueId('var'),
        variable_type: VARIABLE_TYPE,
        key: '',
        value: '',
      });
    },
    removeVariable(index) {
      this.variables.splice(index, 1);
    },

    canRemove(index) {
      return index < this.variables.length - 1;
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
          ref: this.refValue,
          variables_attributes: filteredVariables,
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
        v-for="(variable, index) in variables"
        :key="variable.uniqueId"
        class="gl-display-flex gl-align-items-stretch gl-align-items-center gl-mb-4 gl-ml-n3 gl-pb-2 gl-border-b-solid gl-border-gray-200 gl-border-b-1 gl-flex-direction-column gl-md-flex-direction-row"
        data-testid="ci-variable-row"
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
          @change.once="addEmptyVariable()"
        />
        <gl-form-input
          v-model="variable.value"
          :placeholder="s__('CiVariables|Input variable value')"
          class="gl-mb-3"
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
            <gl-icon class="gl-mr-0! gl-display-none gl-display-md-block" name="clear" />
            <span class="gl-display-md-none">{{ s__('CiVariables|Remove variable') }}</span>
          </gl-button>
          <gl-button
            v-else
            class="gl-md-ml-3 gl-mb-3 gl-display-none gl-display-md-block gl-visibility-hidden"
            icon="clear"
          />
        </template>
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
