<script>
import { GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';

import { START_THREAD } from '../i18n';

export default {
  name: 'DiffDiscussionReply',
  i18n: {
    START_THREAD,
  },
  components: {
    GlButton,
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
    }),
  },
};
</script>

<template>
  <div class="discussion-reply-holder gl-flex clearfix">
    <template v-if="userCanReply">
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
