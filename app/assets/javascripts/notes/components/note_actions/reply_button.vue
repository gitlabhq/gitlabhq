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
      class="note-action-button js-note-action-reply"
      variant="transparent"
      :title="__('Reply to comment')"
      @click="$emit('startReplying')"
    >
      <icon name="comment" css-classes="link-highlight" />
    </gl-button>
  </div>
</template>
