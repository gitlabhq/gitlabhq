<script>
import { GlFormRadioGroup } from '@gitlab/ui';

export default {
  components: { GlFormRadioGroup },
  props: {
    checked: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  methods: {
    onChange(value) {
      this.$emit('change', value);
    },
  },
};
</script>

<template>
  <gl-form-radio-group
    :checked="checked"
    class="multiple-choice-selector gl-border gl-block gl-rounded-base"
    @change="onChange"
  >
    <slot></slot>
  </gl-form-radio-group>
</template>
