<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    cssClass: {
      type: String,
      required: true,
    },
    display: {
      type: Object,
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
  <a
    v-gl-tooltip
    :title="display.tooltip"
    :href="link"
    target="_blank"
    rel="noopener noreferrer nofollow"
    :class="cssClass"
    data-track-event="open_review_app"
    data-track-label="review_app"
  >
    {{ display.text }} <gl-icon class="fgray" name="external-link" />
  </a>
</template>
