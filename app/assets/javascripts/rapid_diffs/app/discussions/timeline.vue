<script>
import { mapState, mapActions } from 'pinia';
import axios from '~/lib/utils/axios_utils';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
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

      const {
        data: { discussion },
      } = await axios.post(this.endpoints.discussions, { note: { note: noteText } });
      this.addDiscussion(discussion);
    },
  },
};
</script>

<template>
  <div class="rd-discussion-timeline gl-my-5" data-testid="commit-timeline">
    <div class="rd-discussion-timeline-comments">
      <diff-discussions :discussions="timelineDiscussions" timeline-layout />
    </div>
    <div
      v-if="!isLoggedIn || userPermissions.can_create_note"
      class="gl-mt-5 gl-rounded-[var(--content-border-radius)] gl-bg-default"
    >
      <note-signed-out-widget v-if="!isLoggedIn" />
      <note-form
        v-else-if="userPermissions.can_create_note"
        class="js-main-target-form"
        :save-note="saveNote"
        :save-button-title="__('Comment')"
        :can-cancel="false"
        :autofocus="false"
      />
    </div>
  </div>
</template>
