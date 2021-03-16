<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';

export default {
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  props: {
    error: {
      type: String,
      required: true,
    },
    wikiPagePath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-alert variant="danger" :dismissible="false">
    <gl-sprintf :message="error">
      <template #wikiLink="{ content }">
        <gl-link :href="wikiPagePath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
