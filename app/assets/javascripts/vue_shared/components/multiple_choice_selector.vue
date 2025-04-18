<script>
import { GlFormCheckboxGroup } from '@gitlab/ui';

export default {
  name: 'MultipleChoiceSelector',
  components: { GlFormCheckboxGroup },
  model: {
    prop: 'checked',
    event: 'input',
  },
  props: {
    checked: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <gl-form-checkbox-group
    :checked="checked"
    class="multiple-choice-selector gl-border gl-block gl-rounded-base"
    @input="$emit('input', $event)"
  >
    <slot></slot>
  </gl-form-checkbox-group>
</template>
