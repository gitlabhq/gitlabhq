<script>
import { mapGetters } from 'vuex';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';

export default {
  name: 'DiffDiscussionReply',
  components: {
    NoteSignedOutWidget,
    ReplyPlaceholder,
  },
  props: {
    hasForm: {
      type: Boolean,
      required: false,
      default: false,
    },
    renderReplyPlaceholder: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getUserData',
      userCanReply: 'userCanReply',
    }),
  },
};
</script>

<template>
  <div class="discussion-reply-holder d-flex clearfix">
    <template v-if="userCanReply">
      <slot v-if="hasForm" name="form"></slot>
      <template v-else-if="renderReplyPlaceholder">
        <reply-placeholder
          :button-text="__('Start a new discussion...')"
          @onClick="$emit('showNewDiscussionForm')"
        />
      </template>
    </template>
    <note-signed-out-widget v-else />
  </div>
</template>
