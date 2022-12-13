<script>
import { GlFormGroup } from '@gitlab/ui';

export default {
  name: 'MessageFormGroup',
  components: {
    GlFormGroup,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    labelFor: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <div>
    <gl-form-group
      :label="label"
      :label-for="labelFor"
      label-cols-sm="2"
      label-class="gl-mt-3"
      label-align-sm="right"
    >
      <slot></slot>
    </gl-form-group>
  </div>
</template>
