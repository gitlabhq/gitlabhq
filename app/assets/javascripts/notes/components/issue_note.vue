<script>
/* global Flash */

import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import IssueNoteHeader from './issue_note_header.vue';
import IssueNoteActions from './issue_note_actions.vue';
import IssueNoteBody from './issue_note_body.vue';

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
    UserAvatarLink,
    IssueNoteHeader,
    IssueNoteActions,
    IssueNoteBody,
  },
  computed: {
    author() {
      return this.note.author;
    },
    classNameBindings() {
      return {
        'is-editing': this.isEditing,
        'disabled-content': this.isDeleting,
      };
    },
    canReportAsAbuse() {
      return this.note.report_abuse_path && this.author.id !== window.gon.current_user_id;
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
          $(this.$refs['noteBody'].$el).renderGFM();
        })
        .catch(() => {
          new Flash('Something went wrong while editing your comment. Please try again.'); // eslint-disable-line
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
};
</script>

<template>
  <li
    class="note timeline-entry"
    :class="classNameBindings">
    <div class="timeline-entry-inner">
      <div class="timeline-icon">
        <user-avatar-link
          :linkHref="author.path"
          :imgSrc="author.avatar_url"
          :imgAlt="author.name"
          :imgSize="40" />
      </div>
      <div class="timeline-content">
        <div class="note-header">
          <issue-note-header
            :author="author"
            :createdAt="note.created_at"
            :noteId="note.id"
            actionText="commented" />
          <issue-note-actions
            :accessLevel="note.human_access"
            :canAward="note.emoji_awardable"
            :canEdit="note.current_user.can_edit"
            :canDelete="note.current_user.can_edit"
            :canReportAsAbuse="canReportAsAbuse"
            :reportAbusePath="note.report_abuse_path"
            :editHandler="editHandler"
            :deleteHandler="deleteHandler" />
        </div>
        <issue-note-body
          :note="note"
          :isEditing="isEditing"
          :formUpdateHandler="formUpdateHandler"
          :formCancelHandler="formCancelHandler"
          ref="noteBody" />
      </div>
    </div>
  </li>
</template>
