<script>
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
  },
};
</script>

<template>
  <li class="note timeline-entry">
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
            :createdAt="note.created_at"
            :notePath="note.path"
            actionText="commented" />
          <issue-note-actions
            :accessLevel="note.human_access"
            :canAward="note.emoji_awardable"
            :canEdit="note.can_edit"
            :canDelete="note.can_edit"
            :reportAbusePath="note.report_abuse_path" />
        </div>
        <issue-note-body :note="note" />
      </div>
    </div>
  </li>
</template>
