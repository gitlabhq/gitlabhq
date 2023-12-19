<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';

export default {
  name: 'AbuseReportNoteActions',
  i18n: {
    editButtonText: __('Edit comment'),
  },
  components: {
    GlButton,
    ReplyButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    showReplyButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    showEditButton: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <reply-button
      v-if="showReplyButton"
      ref="replyButton"
      @startReplying="$emit('startReplying')"
    />
    <gl-button
      v-if="showEditButton"
      v-gl-tooltip
      category="tertiary"
      icon="pencil"
      :title="$options.i18n.editButtonText"
      :aria-label="$options.i18n.editButtonText"
      @click="$emit('startEditing')"
    />
  </div>
</template>
