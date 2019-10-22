<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'ReplyButton',
  components: {
    Icon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <div class="note-actions-item">
    <gl-button
      ref="button"
      v-gl-tooltip
      class="note-action-button"
      data-track-event="click_button"
      data-track-label="reply_comment_button"
      variant="transparent"
      :title="__('Reply to comment')"
      @click="$emit('startReplying')"
    >
      <icon name="comment" class="link-highlight" />
    </gl-button>
  </div>
</template>
