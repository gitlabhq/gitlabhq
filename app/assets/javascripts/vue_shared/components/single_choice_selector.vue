<script>
import { GlFormRadioGroup } from '@gitlab/ui';

export default {
  components: { GlFormRadioGroup },
  props: {
    checked: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      checkedOptions: this.checked,
    };
  },
};
</script>

<template>
  <gl-form-radio-group
    v-model="checkedOptions"
    class="multiple-choice-selector gl-border gl-block gl-rounded-base"
  >
    <slot></slot>
  </gl-form-radio-group>
</template>
