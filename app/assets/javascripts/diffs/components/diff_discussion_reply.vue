<script>
import { GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';
import DiscussionLockedWidget from '~/notes/components/discussion_locked_widget.vue';
import { COMMENT_FORM } from '../../notes/i18n';

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
      getNoteableData: 'getNoteableData',
    }),
    isLoggedIn() {
      return this.currentUser?.id;
    },
    canCreateNote() {
      return this.userCanReply && this.getNoteableData.current_user.can_create_note;
    },
  },
};
</script>

<template>
  <div class="discussion-reply-holder clearfix gl-flex">
    <discussion-locked-widget
      v-if="!canCreateNote && isLoggedIn"
      :issuable-type="$options.i18n.COMMENT_FORM.mergeRequest"
      class="!gl-mt-0 gl-grow"
    />
    <template v-else-if="isLoggedIn">
      <slot v-if="hasForm" name="form"></slot>
      <template v-else-if="renderReplyPlaceholder">
        <gl-button @click="$emit('showNewDiscussionForm')">
          {{ $options.i18n.START_THREAD }}
        </gl-button>
      </template>
    </template>
    <note-signed-out-widget v-else />
  </div>
</template>
