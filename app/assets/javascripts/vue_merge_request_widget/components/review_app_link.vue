<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    link: {
      type: String,
      required: true,
    },
    cssClass: {
      type: String,
      required: true,
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
    {{ __('View app') }} <icon class="fgray" name="external-link" />
  </a>
</template>
