<script>
import { GlForm } from '@gitlab/ui';

export default {
  components: {
    GlForm,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
};
</script>

<template>
  <gl-form />
</template>
