<script>
import { GlTruncate, GlLink, GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
    GlTruncate,
    GlLink,
  },
  props: {
    job: {
      type: Object,
      required: false,
      default: null,
    },
  },
};
</script>
<template>
  <gl-link v-if="job" :href="job.webPath">
    <gl-truncate :text="job.label" />
  </gl-link>
  <gl-badge v-else variant="info">{{ __('API') }}</gl-badge>
</template>
