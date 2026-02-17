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
  <div class="multiple-choice-selector gl-border gl-block gl-rounded-base">
    <gl-form-checkbox-group :checked="checked" @input="$emit('input', $event)">
      <slot></slot>
    </gl-form-checkbox-group>
  </div>
</template>
