<script>
import { GlFormCheckbox } from '@gitlab/ui';

export default {
  components: {
    GlFormCheckbox,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    helpText: {
      type: String,
      required: false,
      default: '',
    },
    label: {
      type: String,
      required: true,
    },
    value: {
      type: Boolean,
      required: true,
    },
    dataQaSelector: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div>
    <input :name="name" type="hidden" :value="value ? '1' : '0'" data-testid="input" />

    <gl-form-checkbox
      :checked="value"
      :data-qa-selector="dataQaSelector"
      @input="$emit('input', $event)"
    >
      <span data-testid="label">{{ label }}</span>
      <template v-if="helpText" #help>
        <span data-testid="helpText">{{ helpText }}</span>
      </template>
    </gl-form-checkbox>
  </div>
</template>
