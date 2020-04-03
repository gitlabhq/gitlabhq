<script>
import { GlFormTextarea } from '@gitlab/ui';

export default {
  components: {
    GlFormTextarea,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <gl-form-textarea :value="value" v-on="$listeners" />
</template>
