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
    target() {
      return this.event.target;
    },
    targetLinkText() {
      return this.target.reference_link_text || this.target.title;
    },
    targetLinkAttributes() {
      return {
        href: this.target.web_url,
        title: this.target.title,
      };
    },
  },
};
</script>

<template>
  <gl-link v-if="target.type" v-bind="targetLinkAttributes">{{ targetLinkText }}</gl-link>
</template>
