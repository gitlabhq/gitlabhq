<script>
import { GlFormCheckbox } from '@gitlab/ui';

export default {
  components: {
    GlFormCheckbox,
  },
  props: {
    id: {
      type: String,
      required: false,
      default: undefined,
    },
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
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    dataTestId: {
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
      :id="id"
      :checked="value"
      :data-testid="dataTestId"
      :disabled="disabled"
      @input="$emit('input', $event)"
    >
      <span data-testid="label">{{ label }}</span>
      <template v-if="helpText" #help>
        <span data-testid="helpText">{{ helpText }}</span>
      </template>
    </gl-form-checkbox>
  </div>
</template>
