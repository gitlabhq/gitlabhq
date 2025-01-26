<script>
import { uniqueId } from 'lodash';
import { GlButton, GlFormGroup, GlFormInputGroup } from '@gitlab/ui';
import { s__ } from '~/locale';

const VALIDATION_STATE = {
  NO_VALIDATION: null,
  INVALID: false,
  VALID: true,
};

export const i18n = {
  addStepButtonLabel: s__('PipelineWizardListWidget|add another step'),
  removeStepButtonLabel: s__('PipelineWizardListWidget|remove step'),
  invalidFeedback: s__('PipelineWizardInputValidation|This value is not valid'),
  errors: {
    needsAnyValueError: s__('PipelineWizardInputValidation|At least one entry is required'),
  },
};

export default {
  i18n,
  name: 'ListWidget',
  components: {
    GlButton,
    GlFormGroup,
    GlFormInputGroup,
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
    default: {
      type: Array,
      required: false,
      default: null,
    },
    invalidFeedback: {
      type: String,
      required: false,
      default: i18n.invalidFeedback,
    },
    id: {
      type: String,
      required: false,
      default: () => uniqueId('listWidget-'),
    },
    pattern: {
      type: String,
      required: false,
      default: null,
    },
    required: {
      type: Boolean,
      required: false,
      default: false,
    },
    validate: {
      type: Boolean,
      required: false,
      default: false,
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
      value: this.default ? this.default.map(this.getAsValueEntry) : [this.getAsValueEntry(null)],
    };
  },
  computed: {
    sanitizedValue() {
      // Filter out empty steps
      return this.value.filter(({ value }) => Boolean(value)).map(({ value }) => value) || [];
    },
    hasAnyValue() {
      return this.value.some(({ value }) => Boolean(value));
    },
    needsAnyValue() {
      return this.required && !this.value.some(({ value }) => Boolean(value));
    },
    inputFieldStates() {
      return this.value.map(this.getValidationStateForValue);
    },
    inputGroupState() {
      return this.showValidationState
        ? this.inputFieldStates.every((v) => v !== VALIDATION_STATE.INVALID)
        : VALIDATION_STATE.NO_VALIDATION;
    },
    showValidationState() {
      return this.touched || this.validate;
    },
    feedback() {
      return this.needsAnyValue
        ? this.$options.i18n.errors.needsAnyValueError
        : this.invalidFeedback;
    },
    inputClass() {
      return this.monospace ? '!gl-font-monospace' : '';
    },
  },
  async created() {
    if (this.default) {
      // emit an updated default value
      await this.$nextTick();
      this.$emit('input', this.sanitizedValue);
    }
  },
  methods: {
    addInputField() {
      this.value.push(this.getAsValueEntry(null));
    },
    getAsValueEntry(value) {
      return {
        id: uniqueId('listValue-'),
        value,
      };
    },
    getValidationStateForValue({ value }, fieldIndex) {
      // If we require a value to be set, mark the first
      // field as invalid, but not all of them.
      if (this.needsAnyValue && fieldIndex === 0) return VALIDATION_STATE.INVALID;
      if (!value) return VALIDATION_STATE.NO_VALIDATION;
      return this.passesPatternValidation(value)
        ? VALIDATION_STATE.VALID
        : VALIDATION_STATE.INVALID;
    },
    passesPatternValidation(v) {
      return !this.pattern || new RegExp(this.pattern).test(v);
    },
    async onValueUpdate() {
      await this.$nextTick();
      this.$emit('input', this.sanitizedValue);
    },
    onTouch() {
      this.touched = true;
    },
    removeValue(index) {
      this.value.splice(index, 1);
      this.onValueUpdate();
    },
  },
};
</script>

<template>
  <div class="gl-mb-6">
    <gl-form-group
      :invalid-feedback="feedback"
      :label="label"
      :label-description="description"
      :state="inputGroupState"
      class="gl-mb-2"
    >
      <gl-form-input-group
        v-for="(item, i) in value"
        :id="item.id"
        :key="item.id"
        v-model.trim="value[i].value"
        :placeholder="i === 0 ? placeholder : undefined"
        :state="inputFieldStates[i]"
        class="gl-mb-2"
        :input-class="inputClass"
        type="text"
        @blur="onTouch"
        @input="onValueUpdate"
      >
        <template #prepend>
          <label :for="item.id" class="gl-sr-only">{{ __('Step') }} {{ i + 1 }}</label>
        </template>
        <template v-if="value.length > 1" #append>
          <gl-button
            :aria-label="$options.i18n.removeStepButtonLabel"
            category="secondary"
            data-testid="remove-step-button"
            icon="remove"
            @click="() => removeValue(i)"
          />
        </template>
      </gl-form-input-group>
    </gl-form-group>
    <gl-button
      category="tertiary"
      data-testid="add-step-button"
      icon="plus"
      size="small"
      variant="confirm"
      @click="addInputField"
    >
      {{ $options.i18n.addStepButtonLabel }}
    </gl-button>
  </div>
</template>
