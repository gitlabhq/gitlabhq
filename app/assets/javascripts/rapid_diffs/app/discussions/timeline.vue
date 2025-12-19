<script>
import { mapState, mapActions } from 'pinia';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { createNoteErrorMessages } from '~/notes/utils';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import DiffDiscussions from './diff_discussions.vue';
import NoteForm from './note_form.vue';
import NoteSignedOutWidget from './note_signed_out_widget.vue';

export default {
  name: 'CommitTimeline',
  components: {
    DiffDiscussions,
    NoteForm,
    NoteSignedOutWidget,
  },
  inject: {
    userPermissions: { type: Object },
    endpoints: { type: Object },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    ...mapState(useDiffDiscussions, ['discussions']),
    timelineDiscussions() {
      return this.discussions.filter(
        (discussion) => !discussion.isForm && !discussion.diff_discussion,
      );
    },
  },
  methods: {
    ...mapActions(useDiffDiscussions, ['addDiscussion']),
    async saveNote(noteText) {
      if (!noteText) return;

      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: noteText });
      if (!confirmSubmit) return;

      try {
        const {
          data: { discussion },
        } = await axios.post(this.endpoints.discussions, { note: { note: noteText } });
        this.addDiscussion(discussion);
      } catch (error) {
        if (error.response) {
          createAlert({
            message: createNoteErrorMessages(error.response.data, error.response.status)[0],
            parent: this.$el,
          });
        }
        throw error;
      }
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <diff-discussions :discussions="timelineDiscussions" />
    <div
      v-if="!isLoggedIn || userPermissions.can_create_note"
      class="gl-rounded-[var(--content-border-radius)] gl-bg-default gl-px-5 gl-py-4"
    >
      <note-signed-out-widget v-if="!isLoggedIn" />
      <note-form
        v-else-if="userPermissions.can_create_note"
        :save-note="saveNote"
        :save-button-title="__('Comment')"
        :can-cancel="false"
        :autofocus="false"
      />
    </div>
  </div>
</template>
