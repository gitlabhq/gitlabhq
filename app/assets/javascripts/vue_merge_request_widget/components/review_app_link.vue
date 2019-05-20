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
  <a :href="link" target="_blank" rel="noopener noreferrer nofollow" :class="cssClass">
    {{ __('View app') }} <icon css-classes="fgray" name="external-link" />
  </a>
</template>
