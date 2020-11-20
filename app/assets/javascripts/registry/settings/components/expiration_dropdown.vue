<script>
import { GlFormGroup, GlFormSelect } from '@gitlab/ui';

export default {
  components: {
    GlFormGroup,
    GlFormSelect,
  },
  props: {
    formOptions: {
      type: Array,
      required: false,
      default: () => [],
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
    name: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-form-group :id="`${name}-form-group`" :label-for="name" :label="label">
    <gl-form-select :id="name" :value="value" :disabled="disabled" @input="$emit('input', $event)">
      <option
        v-for="option in formOptions"
        :key="option.key"
        :value="option.key"
        data-testid="option"
      >
        {{ option.label }}
      </option>
    </gl-form-select>
  </gl-form-group>
</template>
