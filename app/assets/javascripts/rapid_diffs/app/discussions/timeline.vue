<script>
import { isLoggedIn } from '~/lib/utils/common_utils';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { createAlert } from '~/alert';
import { COMMENT_FORM } from '~/notes/i18n';
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
    store: { type: Object },
    userPermissions: { type: Object },
    endpoints: { type: Object },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  methods: {
    async saveNote(noteText) {
      if (!noteText) return;

      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: noteText });
      if (!confirmSubmit) return;

      try {
        await this.store.createNewDiscussion({ note: noteText });
      } catch {
        createAlert({
          message: COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK,
        });
      }
    },
  },
};
</script>

<template>
  <div class="rd-discussion-timeline gl-my-5" data-testid="commit-timeline">
    <div class="rd-discussion-timeline-comments">
      <diff-discussions :discussions="store.timelineDiscussions" timeline-layout />
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
