<script>
import { GlButton } from '@gitlab/ui';
import { mapState } from 'pinia';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';
import DiscussionLockedWidget from '~/notes/components/discussion_locked_widget.vue';
import { useNotes } from '~/notes/store/legacy_notes';
import { COMMENT_FORM } from '~/notes/i18n';
import { START_THREAD } from '../i18n';

export default {
  name: 'DiffDiscussionReply',
  i18n: {
    START_THREAD,
    COMMENT_FORM,
  },
  components: {
    GlButton,
    DiscussionLockedWidget,
    NoteSignedOutWidget,
  },
  props: {
    renderReplyPlaceholder: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(useNotes, {
      currentUser: 'getUserData',
      userCanReply: 'userCanReply',
    }),
    isLoggedIn() {
      return this.currentUser?.id;
    },
  },
};
</script>

<template>
  <div class="discussion-reply-holder gl-flex gl-clearfix">
    <note-signed-out-widget v-if="!isLoggedIn" />
    <discussion-locked-widget
      v-else-if="!userCanReply"
      :issuable-type="$options.i18n.COMMENT_FORM.mergeRequest"
      class="!gl-mt-0 gl-grow"
    />
    <slot v-else name="form">
      <gl-button v-if="renderReplyPlaceholder" @click="$emit('showNewDiscussionForm')">
        {{ $options.i18n.START_THREAD }}
      </gl-button>
    </slot>
  </div>
</template>
