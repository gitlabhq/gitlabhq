<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: { GlLink },
  props: {
    event: {
      type: Object,
      required: true,
    },
  },
  computed: {
    resourceParent() {
      return this.event.resource_parent;
    },
  },
};
</script>

<template>
  <gl-link v-if="resourceParent" :href="resourceParent.web_url">{{
    resourceParent.full_name
  }}</gl-link>
</template>
