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
    description: {
      type: String,
      required: false,
      default: '',
    },
    dropdownClass: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <gl-form-group :id="`${name}-form-group`" :label-for="name" :label="label">
    <div :class="dropdownClass">
      <gl-form-select
        :id="name"
        :value="value"
        :disabled="disabled"
        @input="$emit('input', $event)"
      >
        <option
          v-for="option in formOptions"
          :key="option.key"
          :value="option.key"
          data-testid="option"
        >
          {{ option.label }}
        </option>
      </gl-form-select>
    </div>
    <template v-if="description" #description>
      <span data-testid="description" class="gl-text-subtle">
        {{ description }}
      </span>
    </template>
  </gl-form-group>
</template>
