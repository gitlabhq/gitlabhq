<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';

export default {
  name: 'WorkItemNoteActions',
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
    showReply: {
      type: Boolean,
      required: true,
    },
    showEdit: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <reply-button v-if="showReply" ref="replyButton" @startReplying="$emit('startReplying')" />
    <gl-button
      v-if="showEdit"
      v-gl-tooltip
      data-testid="edit-work-item-note"
      data-track-action="click_button"
      data-track-label="edit_button"
      category="tertiary"
      icon="pencil"
      :title="$options.i18n.editButtonText"
      :aria-label="$options.i18n.editButtonText"
      @click="$emit('startEditing')"
    />
  </div>
</template>
