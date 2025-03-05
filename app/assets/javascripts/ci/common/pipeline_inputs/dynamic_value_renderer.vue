<script>
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';

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
  ARRAY: 'array',
  BOOLEAN: 'boolean',
  NUMBER: 'number',
  STRING: 'string',
};

export default {
  name: 'DynamicValueRenderer',
  components: {
    GlCollapsibleListbox,
    GlFormInput,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  emits: ['update'],
  computed: {
    inputValue: {
      get() {
        // For arrays, convert to JSON string
        if (this.item.type === INPUT_TYPES.ARRAY && Array.isArray(this.item.value)) {
          return JSON.stringify(this.item.value);
        }
        return this.item.value;
      },
      set(newValue) {
        // For arrays, try JSON parse first, then comma-split as fallback
        if (this.item.type === INPUT_TYPES.ARRAY && typeof newValue === 'string') {
          try {
            // Try JSON parse for complex arrays
            const parsed = JSON.parse(newValue);
            this.$emit('update', {
              item: this.item,
              value: Array.isArray(parsed) ? parsed : [parsed],
            });
          } catch {
            // Fallback to comma-split for simple input
            this.$emit('update', {
              item: this.item,
              value: newValue.split(',').map((item) => item.trim()),
            });
          }
        } else {
          this.$emit('update', { item: this.item, value: newValue });
        }
      },
    },
    dropdownOptions() {
      if (this.item.type === INPUT_TYPES.BOOLEAN) {
        return [
          { value: 'true', text: 'true' },
          { value: 'false', text: 'false' },
        ];
      }
      return this.item.options.map((option) => ({ value: option, text: option })) || [];
    },
    headerText() {
      return this.item.type === INPUT_TYPES.BOOLEAN ? __('Value') : __('Options');
    },
    inputType() {
      return this.item.type === INPUT_TYPES.NUMBER ? 'number' : 'text';
    },
    isDropdown() {
      return this.item.type === INPUT_TYPES.BOOLEAN || Boolean(this.item.options?.length);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    v-if="isDropdown"
    v-model="inputValue"
    block
    :aria-label="item.name"
    :header-text="headerText"
    :items="dropdownOptions"
  />
  <gl-form-input v-else v-model="inputValue" :aria-label="item.name" :type="inputType" />
</template>
