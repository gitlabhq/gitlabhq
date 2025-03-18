<script>
import { GlCollapsibleListbox, GlFormInput, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import validation, { initForm } from '~/vue_shared/directives/validation';

/**
 * DynamicValueRenderer
 *
 * This component dynamically renders the appropriate input field based on the data type.
 * It supports multiple input types:
 * - Boolean: Rendered as a dropdown with true/false options
 * - Array: Rendered as a text input field unless options are included
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

const feedbackMap = {
  valueMissing: {
    isInvalid: (el) => el.validity?.valueMissing,
    message: __('This is mandatory and must be defined.'),
  },
  numberTypeMismatch: {
    isInvalid: (el) => {
      return (
        el.dataset.fieldType === INPUT_TYPES.NUMBER &&
        el.value &&
        !Number.isFinite(Number(el.value))
      );
    },
    message: __('The value must contain only numbers.'),
  },
  regexMismatch: {
    isInvalid: (el) => el.validity?.patternMismatch,
    message: __('The value must match the defined regular expression.'),
  },
};

export default {
  name: 'DynamicValueRenderer',
  components: {
    GlCollapsibleListbox,
    GlFormInput,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
            value: this.item.default,
            required: this.item.required || false,
          },
        },
        showValidation: true,
      }),
    };
  },
  computed: {
    inputValue: {
      get() {
        return this.convertToDisplayValue(this.item.default);
      },
      set(newValue) {
        if (newValue === this.convertToDisplayValue(this.item.default)) return;

        const value = this.convertToType(newValue);
        this.$emit('update', {
          item: this.item,
          value,
        });
      },
    },
    dropdownOptions() {
      if (this.item.type === INPUT_TYPES.BOOLEAN) {
        return [
          { value: 'true', text: 'true' },
          { value: 'false', text: 'false' },
        ];
      }
      return this.item.options?.map((option) => ({ value: option, text: option })) || [];
    },
    hasValidationFeedback() {
      return Boolean(this.validationFeedback);
    },
    headerText() {
      return this.item.type === INPUT_TYPES.BOOLEAN ? __('Value') : __('Options');
    },
    invalidTooltipTitle() {
      const field = this.form.fields[this.item.name];

      if (this.item.regex && field?.feedback === feedbackMap.regexMismatch.message) {
        return `${__('Pattern')}: ${this.item.regex}`;
      }

      return '';
    },
    isDropdown() {
      return this.item.type === INPUT_TYPES.BOOLEAN || Boolean(this.item.options?.length);
    },
    validationFeedback() {
      const field = this.form.fields[this.item.name];
      return field?.feedback || '';
    },
  },
  methods: {
    convertToDisplayValue(value) {
      if (!value) {
        return this.item.type === INPUT_TYPES.BOOLEAN ? 'false' : '';
      }

      switch (this.item.type) {
        case INPUT_TYPES.BOOLEAN:
          return value.toString();
        case INPUT_TYPES.ARRAY:
          return Array.isArray(value) ? JSON.stringify(value) : value;
        default:
          return value;
      }
    },
    convertToType(value) {
      switch (this.item.type) {
        case INPUT_TYPES.BOOLEAN:
          return value === 'true';
        case INPUT_TYPES.NUMBER:
          return Number(value);
        default:
          return value;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      v-if="isDropdown"
      v-model="inputValue"
      block
      :aria-label="item.name"
      :header-text="headerText"
      :items="dropdownOptions"
    />
    <template v-else>
      <gl-form-input
        v-model="inputValue"
        v-validation:[form.showValidation]
        :aria-label="item.name"
        :data-field-type="item.type"
        :name="item.name"
        :pattern="item.regex"
        :required="item.required"
        :state="form.fields[item.name].state"
        data-testid="value-input"
      />
      <div
        v-if="hasValidationFeedback"
        v-gl-tooltip="invalidTooltipTitle"
        class="gl-mt-4 gl-text-danger"
        data-testid="validation-feedback"
      >
        {{ validationFeedback }}
      </div>
    </template>
  </div>
</template>
