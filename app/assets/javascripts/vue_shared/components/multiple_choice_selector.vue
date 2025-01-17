<script>
import { GlFormCheckboxGroup } from '@gitlab/ui';

export default {
  components: { GlFormCheckboxGroup },
  props: {
    selected: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      selectedOptions: this.selected,
    };
  },
};
</script>

<template>
  <gl-form-checkbox-group
    v-model="selectedOptions"
    class="multiple-choice-selector gl-border gl-block gl-rounded-base"
  >
    <slot></slot>
  </gl-form-checkbox-group>
</template>
