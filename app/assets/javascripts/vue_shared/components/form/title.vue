<script>
import { GlFormInput, GlFormGroup } from '@gitlab/ui';

export default {
  components: {
    GlFormInput,
    GlFormGroup,
  },
  inheritAttrs: false,
};
</script>
<template>
  <gl-form-group :label="__('Title')" label-for="title-field-edit">
    <gl-form-input v-bind="$attrs" v-on="$listeners" />
  </gl-form-group>
</template>
