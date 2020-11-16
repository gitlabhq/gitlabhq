<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';

export default {
  name: 'ReplyButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <div class="gl-ml-2">
    <gl-button
      ref="button"
      v-gl-tooltip
      data-track-event="click_button"
      data-track-label="reply_comment_button"
      category="tertiary"
      size="small"
      icon="comment"
      :title="__('Reply to comment')"
      :aria-label="__('Reply to comment')"
      @click="$emit('startReplying')"
    />
  </div>
</template>
