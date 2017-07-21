<script>
/* global Flash */

import { mapGetters } from 'vuex';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import issueNoteHeader from './issue_note_header.vue';
import issueNoteActions from './issue_note_actions.vue';
import issueNoteBody from './issue_note_body.vue';
import eventHub from '../event_hub';

export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
      isDeleting: false,
    };
  },
  components: {
    userAvatarLink,
    issueNoteHeader,
    issueNoteActions,
    issueNoteBody,
  },
  computed: {
    ...mapGetters([
      'targetNoteHash',
    ]),
    author() {
      return this.note.author;
    },
    classNameBindings() {
      return {
        'is-editing': this.isEditing,
        'disabled-content': this.isDeleting,
        'js-my-note': this.author.id === window.gon.current_user_id,
        target: this.targetNoteHash === this.noteAnchorId,
      };
    },
    canReportAsAbuse() {
      return this.note.report_abuse_path && this.author.id !== window.gon.current_user_id;
    },
    noteAnchorId() {
      return `note_${this.note.id}`;
    },
  },
  methods: {
    editHandler() {
      this.isEditing = true;
    },
    deleteHandler() {
      const msg = 'Are you sure you want to delete this list?';
      const isConfirmed = confirm(msg); // eslint-disable-line

      if (isConfirmed) {
        this.isDeleting = true;
        this.$store
          .dispatch('deleteNote', this.note)
          .then(() => {
            this.isDeleting = false;
          })
          .catch(() => {
            new Flash('Something went wrong while deleting your note. Please try again.'); // eslint-disable-line
            this.isDeleting = false;
          });
      }
    },
    formUpdateHandler(note) {
      const data = {
        endpoint: this.note.path,
        note: {
          full_data: true,
          target_type: 'issue',
          target_id: this.note.noteable_id,
          note,
        },
      };

      this.$store.dispatch('updateNote', data)
        .then(() => {
          this.isEditing = false;
          $(this.$refs.noteBody.$el).renderGFM();
        })
        .catch(() => {
          Flash('Something went wrong while editing your comment. Please try again.');
        });
    },
    formCancelHandler(shouldConfirm) {
      if (shouldConfirm && this.$refs.noteBody.$refs.noteForm.isDirty) {
        const msg = 'Are you sure you want to cancel editing this comment?';
        const isConfirmed = confirm(msg); // eslint-disable-line
        if (!isConfirmed) {
          return;
        }
      }

      this.isEditing = false;
    },
  },
  created() {
    eventHub.$on('enterEditMode', ({ noteId }) => {
      if (noteId === this.note.id) {
        this.isEditing = true;
        this.$store.dispatch('scrollToNoteIfNeeded', $(this.$el));
      }
    });
  },
};
</script>

<template>
  <li
    class="note timeline-entry"
    :id="noteAnchorId"
    :class="classNameBindings">
    <div class="timeline-entry-inner">
      <div class="timeline-icon">
        <user-avatar-link
          :link-href="author.path"
          :img-src="author.avatar_url"
          :img-alt="author.name"
          :img-size="40" />
      </div>
      <div class="timeline-content">
        <div class="note-header">
          <issue-note-header
            :author="author"
            :created-at="note.created_at"
            :note-id="note.id"
            actionText="commented" />
          <issue-note-actions
            :author-id="author.id"
            :note-id="note.id"
            :access-level="note.human_access"
            :can-edit="note.current_user.can_edit"
            :can-delete="note.current_user.can_edit"
            :can-report-as-abuse="canReportAsAbuse"
            :report-abuse-path="note.report_abuse_path"
            :edit-handler="editHandler"
            :delete-handler="deleteHandler" />
        </div>
        <issue-note-body
          :note="note"
          :can-edit="note.current_user.can_edit"
          :is-editing="isEditing"
          :form-update-handler="formUpdateHandler"
          :form-cancel-handler="formCancelHandler"
          ref="noteBody" />
      </div>
    </div>
  </li>
</template>
