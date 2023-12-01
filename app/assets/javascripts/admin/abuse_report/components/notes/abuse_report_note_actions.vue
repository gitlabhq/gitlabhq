<script>
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';

export default {
  name: 'AbuseReportNoteActions',
  components: {
    ReplyButton,
  },
  props: {
    showReplyButton: {
      type: Boolean,
      required: false,
      default: false,
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
  </div>
</template>
