<script>
import {
  GlButton,
  GlCollapsibleListbox,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlLoadingIcon,
} from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__, __ } from '~/locale';
import InputsAdoptionBanner from '~/ci/common/pipeline_inputs/inputs_adoption_banner.vue';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';
import { CI_VARIABLE_TYPE_FILE, CI_VARIABLE_TYPE_ENV_VAR } from '../pipeline_new/constants';
import VariableValuesListbox from '../pipeline_new/components/variable_values_listbox.vue';

export default {
  name: 'VariablesForm',
  formElementClasses: 'gl-basis-1/4 gl-shrink-0 gl-flex-grow-0',
  textAreaStyle: { height: '32px' },
  typeOptions: [
    {
      text: __('Variable'),
      value: CI_VARIABLE_TYPE_ENV_VAR,
    },
    {
      text: __('File'),
      value: CI_VARIABLE_TYPE_FILE,
    },
  ],
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlLoadingIcon,
    InputsAdoptionBanner,
    Markdown,
    VariableValuesListbox,
  },
  props: {
    initialVariables: {
      type: Array,
      required: false,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    editing: {
      type: Boolean,
      required: false,
      default: false,
    },
    userCalloutsFeatureName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      variables: [...this.initialVariables],
      showVarValues: false,
    };
  },
  computed: {
    varSecurityBtnText() {
      return this.showVarValues ? __('Hide values') : __('Reveal values');
    },
    showSecurityBtn() {
      return this.editing && this.initialVariables.length > 0;
    },
  },
  watch: {
    variables: {
      handler(newVariables) {
        this.$emit('update-variables', newVariables);
      },
      deep: true,
    },
    initialVariables: {
      handler(newValue) {
        this.variables = [...newValue];
        this.addEmptyVariable();
      },
      immediate: true,
    },
  },
  methods: {
    addEmptyVariable() {
      const lastVar = this.variables[this.variables.length - 1];
      if (lastVar?.key === '' && lastVar?.value === '') {
        return;
      }

      this.variables.push({
        uniqueId: uniqueId('var'),
        variableType: CI_VARIABLE_TYPE_ENV_VAR,
        key: '',
        value: '',
        destroy: false,
        empty: true,
      });
    },
    setVariableType(index, type) {
      this.variables[index].variableType = type;
    },
    setVariableValue(index, value) {
      this.variables[index].value = value;
    },
    shouldShowValuesDropdown(valueOptions) {
      return valueOptions?.length > 1;
    },
    createListItemsFromVariableOptions(valueOptions) {
      const uniqueOptions = [...new Set(valueOptions)];

      return uniqueOptions.map((option) => ({
        text: option,
        value: option,
      }));
    },
    getPipelineAriaLabel(index) {
      return `${s__('Pipeline|Variable')} ${index + 1}`;
    },
    canRemove(index) {
      return index < this.variables.length - 1;
    },
    removeVariable(index) {
      this.variables = this.variables.map((v, i) => (i === index ? { ...v, destroy: true } : v));
    },
    displayHiddenChars(index) {
      const isEmpty = this.variables[index]?.empty;
      return this.editing && this.showSecurityBtn && !this.showVarValues && !isEmpty;
    },
    resetVariable(index) {
      const variable = this.variables[index];
      if (variable.value?.length) {
        this.variables[index].empty = false;
      }
    },
  },
};
</script>

<template>
  <gl-form-group id="pipeline-form-ci-variables" class="gl-mb-0" :label="s__('Pipeline|Variables')">
    <gl-loading-icon v-if="isLoading" class="gl-mb-5" size="md" />
    <template v-else>
      <inputs-adoption-banner :feature-name="userCalloutsFeatureName" />
      <gl-form-group class="gl-mb-0">
        <template v-for="(variable, index) in variables">
          <div
            v-if="!variable.destroy"
            :key="variable.uniqueId"
            class="gl-mb-4"
            data-testid="ci-variable-row-container"
          >
            <div class="gl-flex gl-flex-col gl-items-stretch gl-gap-4 @md/panel:gl-flex-row">
              <gl-collapsible-listbox
                :items="$options.typeOptions"
                :selected="variable.variableType"
                :class="$options.formElementClasses"
                :aria-label="getPipelineAriaLabel(index)"
                block
                data-testid="pipeline-form-ci-variable-type"
                @select="setVariableType(index, $event)"
              />
              <gl-form-input
                v-model="variable.key"
                :placeholder="s__('CiVariables|Input variable key')"
                :aria-label="s__('CiVariables|Input variable key')"
                :class="$options.formElementClasses"
                class="gl-self-start"
                data-testid="pipeline-form-ci-variable-key-field"
                @change="addEmptyVariable()"
              />
              <variable-values-listbox
                v-if="shouldShowValuesDropdown(variable.valueOptions)"
                :items="createListItemsFromVariableOptions(variable.valueOptions)"
                :selected="variable.value"
                :class="$options.formElementClasses"
                class="!gl-mr-0 gl-grow"
                data-testid="pipeline-form-ci-variable-value-dropdown"
                @select="setVariableValue(index, $event)"
              />
              <gl-form-textarea
                v-else-if="displayHiddenChars(index)"
                :aria-label="s__('CiVariables|Hidden variable value')"
                value="*****************"
                disabled
                class="!gl-h-7"
                data-testid="pipeline-form-ci-variable-hidden-value"
              />
              <gl-form-textarea
                v-else
                v-model="variable.value"
                :placeholder="s__('CiVariables|Input variable value')"
                :aria-label="s__('CiVariables|Input variable value')"
                :style="$options.textAreaStyle"
                class="gl-min-h-7"
                :no-resize="false"
                data-testid="pipeline-form-ci-variable-value-field"
                @change="resetVariable(index)"
              />

              <template v-if="variables.length > 1">
                <gl-button
                  v-if="canRemove(index)"
                  class="@md/panel:gl-hidden"
                  data-testid="remove-ci-variable-button"
                  size="medium"
                  icon="remove"
                  category="secondary"
                  @click="removeVariable(index)"
                >
                  {{ s__('CiVariables|Remove variable') }}
                </gl-button>

                <!-- for the last row, the button is rendered disabled + invisible so it takes space in the row -->
                <gl-button
                  class="@max-md/panel:gl-hidden"
                  data-testid="remove-ci-variable-button-desktop"
                  size="medium"
                  category="tertiary"
                  icon="remove"
                  :aria-label="s__('CiVariables|Remove variable')"
                  :disabled="!canRemove(index)"
                  :class="{ 'gl-invisible': !canRemove(index) }"
                  @click="removeVariable(index)"
                />
              </template>
            </div>
            <markdown
              v-if="variable.description"
              class="gl-text-subtle"
              :markdown="variable.description"
            />
          </div>
        </template>
        <template #description>
          <slot name="description"></slot>
        </template>
      </gl-form-group>
      <gl-button
        v-if="showSecurityBtn"
        class="gl-mb-5"
        category="secondary"
        variant="confirm"
        data-testid="variable-security-btn"
        @click="showVarValues = !showVarValues"
      >
        {{ varSecurityBtnText }}
      </gl-button>
    </template>
  </gl-form-group>
</template>
