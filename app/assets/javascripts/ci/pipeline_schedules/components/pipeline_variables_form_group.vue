<script>
import {
  GlButton,
  GlCollapsibleListbox,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
} from '@gitlab/ui';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import InputsAdoptionBanner from '~/ci/common/pipeline_inputs/inputs_adoption_banner.vue';
import { VARIABLE_TYPE, FILE_TYPE } from '../constants';

export default {
  name: 'PipelineVariablesFormGroup',
  userCalloutsFeatureName: 'pipeline_schedules_inputs_adoption_banner',
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    InputsAdoptionBanner,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    initialVariables: {
      type: Array,
      required: false,
      default: () => [],
    },
    editing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      variables: this.initialVariables,
      showVarValues: false,
    };
  },
  formElementClasses: 'md:gl-mr-3 gl-mb-3 gl-basis-1/4 gl-shrink-0 gl-flex-grow-0',
  // it's used to prevent the overwrite if 'gl-h-7' or '!gl-h-7' were used
  textAreaStyle: { height: '32px' },
  typeOptions: [
    {
      text: __('Variable'),
      value: VARIABLE_TYPE,
    },
    {
      text: __('File'),
      value: FILE_TYPE,
    },
  ],
  computed: {
    varSecurityBtnText() {
      return this.showVarValues ? __('Hide values') : __('Reveal values');
    },
    isPipelineInputsFeatureAvailable() {
      return this.glFeatures.ciInputsForPipelines;
    },
    hasExistingScheduleVariables() {
      return this.variables.length > 0;
    },
    showVarSecurityBtn() {
      return this.editing && this.hasExistingScheduleVariables;
    },
  },
  watch: {
    variables: {
      handler(newValue) {
        this.$emit('update-variables', newValue);
      },
      deep: true,
    },
    initialVariables: {
      handler(newValue) {
        this.variables = newValue;
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
        variableType: VARIABLE_TYPE,
        key: '',
        value: '',
        destroy: false,
        empty: true,
      });
    },
    setVariableType(typeValue, key) {
      const variable = this.variables.find((v) => v.key === key);
      variable.variableType = typeValue;
    },
    removeVariable(index) {
      this.variables[index].destroy = true;
    },
    canRemove(index) {
      return index < this.variables.length - 1;
    },
    displayHiddenChars(variable) {
      return (
        this.editing && this.hasExistingScheduleVariables && !this.showVarValues && !variable.empty
      );
    },
    resetVariable(index) {
      this.variables[index].empty = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group
      id="pipeline-form-ci-variable-type"
      class="gl-mb-0"
      :label="s__('Pipeline|Variables')"
    >
      <inputs-adoption-banner
        v-if="isPipelineInputsFeatureAvailable"
        class="gl-mt-0"
        :feature-name="$options.userCalloutsFeatureName"
      />
      <div v-for="(variable, index) in variables" :key="`var-${index}`">
        <div
          v-if="!variable.destroy"
          class="gl-mb-3 gl-flex gl-flex-col gl-items-stretch gl-pb-2 md:gl-flex-row md:gl-items-start"
          data-testid="ci-variable-row"
        >
          <gl-collapsible-listbox
            :items="$options.typeOptions"
            :selected="variable.variableType"
            :class="$options.formElementClasses"
            :aria-label="s__('Pipeline|Variable type')"
            toggle-aria-labelled-by="pipeline-form-ci-variable-type"
            block
            data-testid="pipeline-form-ci-variable-type"
            @select="setVariableType($event, variable.key)"
          />

          <gl-form-input
            v-model="variable.key"
            :placeholder="s__('CiVariables|Input variable key')"
            :aria-label="s__('CiVariables|Input variable key')"
            :class="$options.formElementClasses"
            data-testid="pipeline-form-ci-variable-key"
            @change="addEmptyVariable()"
          />

          <gl-form-textarea
            v-if="displayHiddenChars(variable)"
            value="*****************"
            disabled
            class="gl-mb-3 !gl-h-7"
            data-testid="pipeline-form-ci-variable-hidden-value"
          />

          <gl-form-textarea
            v-else
            v-model="variable.value"
            :placeholder="s__('CiVariables|Input variable value')"
            :aria-label="s__('CiVariables|Input variable value')"
            class="gl-mb-3 gl-min-h-7"
            :style="$options.textAreaStyle"
            :no-resize="false"
            data-testid="pipeline-form-ci-variable-value"
            @change="resetVariable(index)"
          />

          <template v-if="variables.length > 1">
            <gl-button
              v-if="canRemove(index)"
              class="gl-mb-3 md:gl-ml-3"
              data-testid="remove-ci-variable-row"
              variant="danger"
              category="secondary"
              icon="clear"
              :aria-label="s__('CiVariables|Remove variable')"
              @click="removeVariable(index)"
            />
            <gl-button
              v-else
              class="gl-invisible gl-mb-3 gl-hidden md:gl-ml-3 md:gl-block"
              icon="clear"
              :aria-label="s__('CiVariables|Remove variable')"
            />
          </template>
        </div>
      </div>
    </gl-form-group>

    <gl-button
      v-if="showVarSecurityBtn"
      class="gl-mb-5"
      category="secondary"
      variant="confirm"
      data-testid="variable-security-btn"
      @click="showVarValues = !showVarValues"
    >
      {{ varSecurityBtnText }}
    </gl-button>
  </div>
</template>
