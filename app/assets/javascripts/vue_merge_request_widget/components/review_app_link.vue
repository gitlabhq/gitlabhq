<script>
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    cssClass: {
      type: String,
      required: true,
    },
    isCurrent: {
      type: Boolean,
      required: true,
    },
    link: {
      type: String,
      required: true,
    },
  },
  computed: {
    linkText() {
      return this.isCurrent ? __('View app') : __('View previous app');
    },
  },
};
</script>
<template>
  <a
    :href="link"
    target="_blank"
    rel="noopener noreferrer nofollow"
    :class="cssClass"
    data-track-event="open_review_app"
    data-track-label="review_app"
  >
    {{ linkText }} <icon class="fgray" name="external-link" />
  </a>
</template>
