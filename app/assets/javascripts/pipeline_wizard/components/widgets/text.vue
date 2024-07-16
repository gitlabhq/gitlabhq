<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__ } from '~/locale';

const VALIDATION_STATE = {
  NO_VALIDATION: null,
  INVALID: false,
  VALID: true,
};

export default {
  name: 'TextWidget',
  components: {
    GlFormGroup,
    GlFormInput,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    placeholder: {
      type: String,
      required: false,
      default: null,
    },
    invalidFeedback: {
      type: String,
      required: false,
      default: s__('PipelineWizardInputValidation|This value is not valid'),
    },
    id: {
      type: String,
      required: false,
      default: () => uniqueId('textWidget-'),
    },
    pattern: {
      type: String,
      required: false,
      default: null,
    },
    validate: {
      type: Boolean,
      required: false,
      default: false,
    },
    required: {
      type: Boolean,
      required: false,
      default: false,
    },
    default: {
      type: String,
      required: false,
      default: null,
    },
    monospace: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      touched: false,
      value: this.default,
    };
  },
  computed: {
    validationState() {
      if (!this.showValidationState) return VALIDATION_STATE.NO_VALIDATION;
      if (this.isRequiredButEmpty) return VALIDATION_STATE.INVALID;
      return this.needsValidationAndPasses ? VALIDATION_STATE.VALID : VALIDATION_STATE.INVALID;
    },
    showValidationState() {
      return this.touched || this.validate;
    },
    isRequiredButEmpty() {
      return this.required && !this.value;
    },
    needsValidationAndPasses() {
      return !this.pattern || new RegExp(this.pattern).test(this.value);
    },
    invalidFeedbackMessage() {
      return this.isRequiredButEmpty
        ? s__('PipelineWizardInputValidation|This field is required')
        : this.invalidFeedback;
    },
    inputClass() {
      return this.monospace ? '!gl-font-monospace' : '';
    },
  },
  watch: {
    validationState(v) {
      this.$emit('update:valid', v);
    },
    value(v) {
      this.$emit('input', v.trim());
    },
  },
  created() {
    if (this.default) {
      this.$emit('input', this.value);
    }
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :description="description"
      :invalid-feedback="invalidFeedbackMessage"
      :label="label"
      :label-for="id"
      :state="validationState"
    >
      <gl-form-input
        :id="id"
        v-model="value"
        :class="inputClass"
        :placeholder="placeholder"
        :state="validationState"
        type="text"
        @blur="touched = true"
      />
    </gl-form-group>
  </div>
</template>
