<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
  },
  props: {
    commentsCount: {
      type: Number,
      required: true,
    },
  },
  computed: {
    tooltipText() {
      return n__('%d comment on this commit', '%d comments on this commit', this.commentsCount);
    },
    showCommentButton() {
      return this.commentsCount > 0;
    },
  },
};
</script>

<template>
  <span
    v-if="showCommentButton"
    v-gl-tooltip
    class="gl-display-none gl-sm-display-inline-block"
    tabindex="0"
    :title="tooltipText"
    data-testid="comment-button-wrapper"
  >
    <gl-button icon="comment" class="gl-mr-3" disabled>
      {{ commentsCount }}
    </gl-button>
  </span>
</template>
