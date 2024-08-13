<script>
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
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
    size: {
      type: String,
      required: false,
      default: 'medium',
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip
    :title="display.tooltip"
    :href="link"
    :size="size"
    target="_blank"
    rel="noopener noreferrer nofollow"
    is-unsafe-link
    :class="cssClass"
    data-track-action="open_review_app"
    data-track-label="review_app"
  >
    {{ display.text }} <gl-icon variant="subtle" name="external-link" />
  </gl-button>
</template>
