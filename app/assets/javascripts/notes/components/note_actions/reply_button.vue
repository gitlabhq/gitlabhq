<script>
import { GlTooltipDirective, GlDeprecatedButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'ReplyButton',
  components: {
    Icon,
    GlDeprecatedButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <div class="note-actions-item">
    <gl-deprecated-button
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
    </gl-deprecated-button>
  </div>
</template>
