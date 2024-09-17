<script>
import { GlLink, GlSprintf } from '@gitlab/ui';

export default {
  components: {
    GlLink,
    GlSprintf,
  },
  props: {
    message: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <span>
    <gl-sprintf :message="message">
      <template #link="{ content }">
        <gl-link class="gl-inline-block" :href="link" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </span>
</template>
