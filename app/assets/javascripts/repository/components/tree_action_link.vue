<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      required: true,
    },
    cssClass: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <gl-link :href="path" :class="cssClass" class="btn gl-button">{{ text }}</gl-link>
</template>
