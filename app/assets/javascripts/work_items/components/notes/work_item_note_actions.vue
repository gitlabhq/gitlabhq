<script>
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';

export default {
  name: 'WorkItemNoteActions',
  components: {
    ReplyButton,
  },
  props: {
    showReply: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <reply-button v-if="showReply" ref="replyButton" @startReplying="$emit('startReplying')" />
  </div>
</template>
