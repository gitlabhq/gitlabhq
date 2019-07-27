<script>
import { mapGetters } from 'vuex';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  name: 'DiffDiscussionReply',
  components: {
    NoteSignedOutWidget,
    ReplyPlaceholder,
    UserAvatarLink,
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
        <user-avatar-link
          :link-href="currentUser.path"
          :img-src="currentUser.avatar_url"
          :img-alt="currentUser.name"
          :img-size="40"
          class="d-none d-sm-block"
        />
        <reply-placeholder
          :button-text="__('Start a new discussion...')"
          @onClick="$emit('showNewDiscussionForm')"
        />
      </template>
    </template>
    <note-signed-out-widget v-else />
  </div>
</template>
