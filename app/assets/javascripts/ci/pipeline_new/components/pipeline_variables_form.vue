<script>
import {
  GlIcon,
  GlButton,
  GlCollapsibleListbox,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
} from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import { fetchPolicies } from '~/lib/graphql';
import filterVariables from '../utils/filter_variables';
import {
  CONFIG_VARIABLES_TIMEOUT,
  CI_VARIABLE_TYPE_FILE,
  CI_VARIABLE_TYPE_ENV_VAR,
} from '../constants';
import ciConfigVariablesQuery from '../graphql/queries/ci_config_variables.graphql';
import VariableValuesListbox from './variable_values_listbox.vue';

let pollTimeout;
export const POLLING_INTERVAL = 2000;

export default {
  name: 'PipelineVariablesForm',
  formElementClasses: 'gl-basis-1/4 gl-shrink-0 gl-flex-grow-0',
  learnMorePath: helpPagePath('ci/variables/_index', {
    anchor: 'cicd-variable-precedence',
  }),
  // this height value is used inline on the textarea to match the input field height
  // it's used to prevent the overwrite if 'gl-h-7' or '!gl-h-7' were used
  textAreaStyle: { height: '32px' },
  components: {
    GlIcon,
    GlButton,
    GlCollapsibleListbox,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    VariableValuesListbox,
  },
  inject: ['projectPath'],
  props: {
    fileParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isMaintainer: {
      type: Boolean,
      required: true,
    },
    refParam: {
      type: String,
      required: true,
    },
    settingsLink: {
      type: String,
      required: true,
    },
    variableParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      ciConfigVariables: null,
      configVariablesWithDescription: {},
      form: {},
    };
  },
  apollo: {
    ciConfigVariables: {
      fetchPolicy: fetchPolicies.NO_CACHE,
      query: ciConfigVariablesQuery,
      skip() {
        return Object.keys(this.form).includes(this.refParam);
      },
      variables() {
        return {
          fullPath: this.projectPath,
          ref: this.refParam,
        };
      },
      update({ project }) {
        return project?.ciConfigVariables || [];
      },
      result() {
        // API cache is empty when ciConfigVariables === null, so we need to
        // poll while cache values are being populated in the backend.
        // After CONFIG_VARIABLES_TIMEOUT ms have passed, we stop polling
        // and populate the form regardless.
        if (this.isFetchingCiConfigVariables && !pollTimeout) {
          pollTimeout = setTimeout(() => {
            this.ciConfigVariables = [];
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
        reportToSentry(this.$options.name, error);
      },
      pollInterval: POLLING_INTERVAL,
    },
  },
  computed: {
    descriptions() {
      return this.form[this.refParam]?.descriptions ?? {};
    },
    isFetchingCiConfigVariables() {
      return this.ciConfigVariables === null;
    },
    isLoading() {
      return this.$apollo.queries.ciConfigVariables.loading || this.isFetchingCiConfigVariables;
    },
    isMobile() {
      return ['sm', 'xs'].includes(GlBreakpointInstance.getBreakpointSize());
    },
    removeButtonCategory() {
      return this.isMobile ? 'secondary' : 'tertiary';
    },
    variables() {
      return this.form[this.refParam]?.variables ?? [];
    },
    variableTypeListboxItems() {
      return [
        {
          value: CI_VARIABLE_TYPE_ENV_VAR,
          text: s__('Pipeline|Variable'),
        },
        {
          value: CI_VARIABLE_TYPE_FILE,
          text: s__('Pipeline|File'),
        },
      ];
    },
  },
  watch: {
    variables: {
      handler(newVariables) {
        this.$emit('variables-updated', filterVariables(newVariables));
      },
      deep: true,
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
        variableType: CI_VARIABLE_TYPE_ENV_VAR,
        key: '',
        value: '',
      });
    },
    canRemove(index) {
      return index < this.variables.length - 1;
    },
    clearPolling() {
      clearTimeout(pollTimeout);
      this.$apollo.queries.ciConfigVariables.stopPolling();
    },
    createListItemsFromVariableOptions(key) {
      return this.configVariablesWithDescription.options[key].map((option) => ({
        text: option,
        value: option,
      }));
    },
    getPipelineAriaLabel(index) {
      return `${s__('Pipeline|Variable')} ${index + 1}`;
    },
    populateForm() {
      this.configVariablesWithDescription = this.ciConfigVariables.reduce(
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

      this.form = {
        ...this.form,
        [this.refParam]: {
          descriptions: this.configVariablesWithDescription.descriptions,
          variables: [],
        },
      };

      // Add default variables from yml
      this.setVariableParams(
        this.refParam,
        CI_VARIABLE_TYPE_ENV_VAR,
        this.configVariablesWithDescription.values,
      );

      // Add/update variables, e.g. from query string
      if (this.variableParams) {
        this.setVariableParams(this.refParam, CI_VARIABLE_TYPE_ENV_VAR, this.variableParams);
      }

      if (this.fileParams) {
        this.setVariableParams(this.refParam, CI_VARIABLE_TYPE_FILE, this.fileParams);
      }

      // Adds empty var at the end of the form
      this.addEmptyVariable(this.refParam);
    },
    removeVariable(index) {
      this.variables.splice(index, 1);
    },
    setVariableAttribute(key, attribute, value) {
      const { variables } = this.form[this.refParam];
      const variable = variables.find((v) => v.key === key);
      variable[attribute] = value;
    },
    setVariable(refValue, { type, key, value }) {
      const { variables } = this.form[refValue];

      const variable = variables.find((v) => v.key === key);
      if (variable) {
        variable.variableType = type;
        variable.value = value;
      } else {
        variables.push({
          uniqueId: uniqueId(`var-${refValue}`),
          key,
          value,
          variableType: type,
        });
      }
    },
    setVariableParams(refValue, type, paramsObj) {
      Object.entries(paramsObj).forEach(([key, value]) => {
        this.setVariable(refValue, { type, key, value });
      });
    },
    shouldShowValuesDropdown(key) {
      return this.configVariablesWithDescription.options[key]?.length > 1;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" class="gl-mb-5" size="md" />
    <gl-form-group v-else :label="s__('Pipeline|Variables')" class="gl-mb-0">
      <div
        v-for="(variable, index) in variables"
        :key="variable.uniqueId"
        class="gl-mb-4"
        data-testid="ci-variable-row-container"
      >
        <div class="gl-flex gl-flex-col gl-items-stretch gl-gap-4 md:gl-flex-row">
          <gl-collapsible-listbox
            :items="variableTypeListboxItems"
            :selected="variable.variableType"
            block
            fluid-width
            :aria-label="getPipelineAriaLabel(index)"
            :class="$options.formElementClasses"
            data-testid="pipeline-form-ci-variable-type"
            @select="setVariableAttribute(variable.key, 'variableType', $event)"
          />
          <gl-form-input
            v-model="variable.key"
            :placeholder="s__('CiVariables|Input variable key')"
            :class="$options.formElementClasses"
            data-testid="pipeline-form-ci-variable-key-field"
            @change="addEmptyVariable(refParam)"
          />
          <variable-values-listbox
            v-if="shouldShowValuesDropdown(variable.key)"
            :items="createListItemsFromVariableOptions(variable.key)"
            :selected="variable.value"
            :class="$options.formElementClasses"
            class="!gl-mr-0 gl-grow"
            data-testid="pipeline-form-ci-variable-value-dropdown"
            @select="setVariableAttribute(variable.key, 'value', $event)"
          />
          <gl-form-textarea
            v-else
            v-model="variable.value"
            :placeholder="s__('CiVariables|Input variable value')"
            :style="$options.textAreaStyle"
            :no-resize="false"
            data-testid="pipeline-form-ci-variable-value-field"
          />
          <template v-if="variables.length > 1">
            <gl-button
              v-if="canRemove(index)"
              size="small"
              class="gl-shrink-0"
              data-testid="remove-ci-variable-row"
              :category="removeButtonCategory"
              :aria-label="s__('CiVariables|Remove variable')"
              @click="removeVariable(index)"
            >
              <gl-icon class="!gl-mr-0" name="remove" />
              <span class="md:gl-hidden">{{ s__('CiVariables|Remove variable') }}</span>
            </gl-button>
            <gl-button
              v-else
              class="gl-invisible gl-hidden gl-shrink-0 md:gl-block"
              icon="remove"
              :aria-label="s__('CiVariables|Remove variable')"
            />
          </template>
        </div>
        <div v-if="descriptions[variable.key]" class="gl-text-subtle">
          {{ descriptions[variable.key] }}
        </div>
      </div>
      <template #description>
        <gl-sprintf
          :message="
            s__(
              'Pipeline|Specify variable values to be used in this run. The variables specified in the configuration file as well as %{linkStart}CI/CD settings%{linkEnd} are used by default.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link v-if="isMaintainer" :href="settingsLink" data-testid="ci-cd-settings-link">
              {{ content }}
            </gl-link>
            <template v-else>{{ content }}</template>
          </template>
        </gl-sprintf>
        <gl-link :href="$options.learnMorePath" target="_blank">
          {{ __('Learn more') }}
        </gl-link>
        <div class="gl-mt-4 gl-text-subtle">
          <gl-sprintf
            :message="
              s__(
                'CiVariables|Variables specified here are %{boldStart}expanded%{boldEnd} and not %{boldStart}masked.%{boldEnd}',
              )
            "
          >
            <template #bold="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </div>
      </template>
    </gl-form-group>
  </div>
</template>
