<script>
import IssueNote from './issue_note.vue';
import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import IssueNoteHeader from './issue_note_header.vue';
import IssueNoteActions from './issue_note_actions.vue';
import IssueNoteEditedText from './issue_note_edited_text.vue';

export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      registerLink: '#',
      signInLink: '#',
    };
  },
  computed: {
    discussion() {
      return this.note.notes[0];
    },
    author() {
      return this.discussion.author;
    },
  },
  components: {
    IssueNote,
    UserAvatarLink,
    IssueNoteHeader,
    IssueNoteActions,
    IssueNoteEditedText,
  },
  mounted() {
    // We need to grab the register and sign in links from DOM for the time being.
    const registerLink = document.querySelector('.js-disabled-comment .js-register-link');
    const signInLink = document.querySelector('.js-disabled-comment .js-sign-in-link');

    if (registerLink && signInLink) {
      this.registerLink = registerLink.getAttribute('href');
      this.signInLink = signInLink.getAttribute('href');
    }
  },
};
</script>

<template>
  <li class="note note-discussion timeline-entry">
    <div class="timeline-entry-inner">
      <div class="timeline-icon">
        <user-avatar-link
          :link-href="author.path"
          :img-src="author.avatar_url"
          :img-alt="author.name"
          :img-size="40" />
      </div>
      <div class="timeline-content">
        <div class="discussion">
          <div class="discussion-header">
            <issue-note-header
              :author="author"
              :createdAt="discussion.created_at"
              :notePath="discussion.path"
              :includeToggle="true"
              :discussionId="note.id"
              actionText="started a discussion" />
            <issue-note-edited-text
              v-if="note.last_updated_by"
              :editedAt="note.last_updated_at"
              :editedBy="note.last_updated_by"
              actionText="Last updated"
              className="discussion-headline-light js-discussion-headline" />
            </div>
          </div>
          <div
            v-if="note.expanded"
            class="discussion-body">
            <div class="panel panel-default">
              <div class="discussion-notes">
                <ul class="notes">
                  <issue-note
                    v-for="note in note.notes"
                    key="note.id"
                    :note="note" />
                </ul>
                <div class="flash-container"></div>
                <div class="discussion-reply-holder">
                  <button
                    v-if="note.can_reply"
                    type="button"
                    class="btn btn-text-field js-discussion-reply-button"
                    title="Add a reply"></button>
                  <div
                    v-if="!note.can_reply"
                    class="disabled-comment text-center">
                    Please
                    <a :href="registerLink">register</a>
                    or
                    <a :href="signInLink">sign in</a>
                    to reply
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </li>
</template>
