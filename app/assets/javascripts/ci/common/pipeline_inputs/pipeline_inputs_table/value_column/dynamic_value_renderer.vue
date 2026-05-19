<script>
import { GlCollapsibleListbox, GlFormInput, GlFormTextarea } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import validation, { initForm } from '~/vue_shared/directives/validation';
import BooleanCell from './boolean_cell.vue';

/**
 * DynamicValueRenderer
 *
 * This component dynamically renders the appropriate input field based on the data type.
 * It supports multiple input types:
 * - Boolean: Rendered as a dropdown with true/false options
 * - Array: Rendered as a text area input field unless options are included
 * - Number: Rendered as a number input field unless options are included
 * - String/Others: Rendered as a text input field unless options are included
 *
 * The component emits update events when values change, allowing parent components
 * to track and manage the state of these inputs.
 */

const INPUT_TYPES = {
  ARRAY: 'ARRAY',
  BOOLEAN: 'BOOLEAN',
  NUMBER: 'NUMBER',
  STRING: 'STRING',
};

const MAX_NUMBER_VALUE = Number.MAX_SAFE_INTEGER;
const MIN_NUMBER_VALUE = Number.MIN_SAFE_INTEGER;

const VALIDATION_MESSAGES = {
  ARRAY_FORMAT_MISMATCH: __(
    'The value must be a valid JSON array format: [1,2,3] or [{"key": "value"}]',
  ),
  GENERAL_FORMAT_MISMATCH: __('Please match the requested format.'),
  REGEX_MISMATCH: __('The value must match the defined regular expression.'),
  VALUE_MISSING: __('This is required and must be defined.'),
};

const feedbackMap = {
  arrayFormatMismatch: {
    isInvalid: (el) => {
      if (el.dataset.jsonArray !== 'true' || !el.value) return false;

      try {
        const isValid = Array.isArray(JSON.parse(el.value));
        // we use setCustomValidity to set the message that appears when the user clicks submit
        el.setCustomValidity(isValid ? '' : VALIDATION_MESSAGES.GENERAL_FORMAT_MISMATCH);
        return !isValid;
      } catch {
        el.setCustomValidity(VALIDATION_MESSAGES.GENERAL_FORMAT_MISMATCH);
        return true;
      }
    },
    message: __('The value must be a valid JSON array format: [1,2,3] or [{"key": "value"}]'),
  },
  regexMismatch: {
    isInvalid: (el) => el.validity?.patternMismatch,
    message: VALIDATION_MESSAGES.REGEX_MISMATCH,
  },
  valueMissing: {
    isInvalid: (el) => el.validity?.valueMissing,
    message: VALIDATION_MESSAGES.VALUE_MISSING,
  },
};

export default {
  name: 'DynamicValueRenderer',
  MAX_NUMBER_VALUE,
  MIN_NUMBER_VALUE,
  components: {
    BooleanCell,
    GlCollapsibleListbox,
    GlFormInput,
    GlFormTextarea,
  },
  directives: {
    validation: validation(feedbackMap),
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  emits: ['update'],
  data() {
    return {
      form: initForm({
        fields: {
          [this.item.name]: {
            value: this.item.value,
            required: this.item.required || false,
          },
        },
        showValidation: true,
      }),
      searchTerm: '',
    };
  },
  computed: {
    inputValue: {
      get() {
        return this.convertToDisplayValue(this.item.value);
      },
      set(newValue) {
        if (newValue === this.convertToDisplayValue(this.item.value)) return;

        // convert to number if number type
        const value = this.item.type === INPUT_TYPES.NUMBER ? Number(newValue) : newValue;
        this.emitUpdate({ value });
      },
    },
    dropdownOptions() {
      return this.item.options?.map((option) => ({ value: option, text: String(option) })) || [];
    },
    filteredDropdownOptions() {
      if (!this.searchTerm) {
        return this.dropdownOptions;
      }

      const term = this.searchTerm.toLowerCase();
      return this.dropdownOptions.filter((item) => item.text.toLowerCase().includes(term));
    },
    hasArrayFormatError() {
      const field = this.form.fields[this.item.name];
      return this.isArrayType && field?.feedback === feedbackMap.arrayFormatMismatch.message;
    },
    hasValidationFeedback() {
      return Boolean(this.validationFeedback);
    },
    isArrayType() {
      return this.item.type === INPUT_TYPES.ARRAY && Boolean(!this.item.options?.length);
    },
    isBooleanType() {
      return this.item.type === INPUT_TYPES.BOOLEAN && !this.item.options?.length;
    },
    isNumberType() {
      return this.item.type === INPUT_TYPES.NUMBER && !this.item.options?.length;
    },
    isDropdown() {
      return Boolean(this.item.options?.length);
    },
    isMultiSelectDropdown() {
      return this.isDropdown && this.item.type === INPUT_TYPES.ARRAY;
    },
    toggleText() {
      if (!this.inputValue?.length) {
        return __('Select option');
      }

      if (this.item.type === INPUT_TYPES.ARRAY) {
        return this.inputValue.length > 1
          ? sprintf(__('%{number} options selected'), { number: this.inputValue.length })
          : this.inputValue[0];
      }

      return this.inputValue;
    },

    validationFeedback() {
      const field = this.form.fields[this.item.name];
      const feedback = field?.feedback || '';

      return feedback === feedbackMap.regexMismatch.message && this.item.regex
        ? `${feedback} ${__('Pattern')}: ${this.item.regex}`
        : feedback;
    },
    validationState() {
      // Override validation state for array format errors for our custom validation
      // This is also responsible for turning the border red when the input is invalid
      if (this.hasArrayFormatError) {
        return false;
      }

      const field = this.form.fields[this.item.name];
      return field?.state;
    },
  },
  methods: {
    convertToDisplayValue(value) {
      if (value == null || value === '') {
        return '';
      }

      return this.item.type === INPUT_TYPES.ARRAY &&
        Array.isArray(value) &&
        !this.isMultiSelectDropdown
        ? JSON.stringify(value)
        : value;
    },
    emitUpdate({ value }) {
      this.$emit('update', {
        item: this.item,
        value,
      });
    },
  },
};
</script>

<template>
  <div>
    <!-- Dropdown for any type with options -->
    <gl-collapsible-listbox
      v-if="isDropdown"
      v-model="inputValue"
      block
      searchable
      :multiple="isMultiSelectDropdown"
      :aria-label="item.name"
      toggle-class="!gl-pl-4"
      :toggle-text="toggleText"
      :header-text="__('Options')"
      :items="filteredDropdownOptions"
      @search="searchTerm = $event"
    />

    <!-- Button cell for boolean types -->
    <boolean-cell v-else-if="isBooleanType" :input="item" @update="emitUpdate" />

    <!-- Textarea for arrays without options -->
    <gl-form-textarea
      v-else-if="isArrayType"
      v-model="inputValue"
      v-validation:[form.showValidation]
      :aria-label="item.name"
      :data-json-array="'true'"
      :name="item.name"
      :required="item.required"
      :state="validationState"
      rows="3"
    />

    <!-- Number input for numbers without options -->
    <gl-form-input
      v-else-if="isNumberType"
      v-model="inputValue"
      v-validation:[form.showValidation]
      step="any"
      type="number"
      :aria-label="item.name"
      :data-field-type="item.type"
      :min="$options.MIN_NUMBER_VALUE"
      :max="$options.MAX_NUMBER_VALUE"
      :name="item.name"
      :required="item.required"
      :state="validationState"
    />

    <!-- Text input for strings without options -->
    <gl-form-input
      v-else
      v-model="inputValue"
      v-validation:[form.showValidation]
      :aria-label="item.name"
      :data-field-type="item.type"
      :name="item.name"
      :pattern="item.regex"
      :required="item.required"
      :state="validationState"
    />

    <!-- Validation feedback -->
    <div
      v-if="hasValidationFeedback"
      class="gl-mt-4 gl-text-danger"
      data-testid="validation-feedback"
    >
      {{ validationFeedback }}
    </div>
  </div>
</template>
