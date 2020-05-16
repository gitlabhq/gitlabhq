<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: true,
    },
  },
  methods: {
    onUpdate(event) {
      this.$emit('onUpdate', this.name, event.target.value);
    },
  },
};
</script>
<template>
  <gl-form-group :label="label">
    <gl-form-input
      :value="value"
      :name="name"
      @keyup.native.enter="onUpdate"
      @blur.native="onUpdate"
    />
  </gl-form-group>
</template>
