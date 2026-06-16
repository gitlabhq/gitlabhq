<script>
import { GlLink } from '@gitlab/ui';

export default {
  name: 'MilestoneLink',
  components: {
    GlLink,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    webPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <gl-link :href="webPath" target="_blank" variant="meta">{{ title }}</gl-link>
</template>
