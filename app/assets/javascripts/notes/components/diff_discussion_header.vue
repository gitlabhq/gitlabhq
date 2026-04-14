<script>
import { GlAvatar, GlAvatarLink, GlSprintf } from '@gitlab/ui';
import { mapActions } from 'pinia';
import { truncateSha } from '~/lib/utils/text_utility';
import { s__, __ } from '~/locale';
import { FILE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { useNotes } from '~/notes/store/legacy_notes';
import NoteEditedText from './note_edited_text.vue';
import NoteHeader from './note_header.vue';
import ToggleRepliesWidget from './toggle_replies_widget.vue';

export default {
  name: 'DiffDiscussionHeader',
  components: {
    GlAvatar,
    GlAvatarLink,
    GlSprintf,
    NoteEditedText,
    NoteHeader,
    ToggleRepliesWidget,
  },
  inject: {
    navigateToDiffNote: { default: null },
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    notes() {
      return this.discussion.notes;
    },
    firstNote() {
      return this.notes[0];
    },
    author() {
      return this.firstNote.author;
    },
    resolvedText() {
      return this.discussion.resolved_by_push ? __('Automatically resolved') : __('Resolved');
    },
    headerMessage() {
      const {
        for_commit: isForCommit,
        diff_discussion: isDiffDiscussion,
        active: isActive,
        commit_id: commitId,
        position,
      } = this.discussion;

      if (isForCommit) {
        return s__('MergeRequests|started a thread on commit %{link}');
      }
      if (isDiffDiscussion && commitId) {
        return isActive
          ? s__('MergeRequests|started a thread on commit %{link}')
          : s__('MergeRequests|started a thread on an outdated change in commit %{link}');
      }
      if (isDiffDiscussion && position?.position_type === FILE_DIFF_POSITION_TYPE) {
        return isActive
          ? s__('MergeRequests|started a thread on %{linkStart}a file%{linkEnd}')
          : s__('MergeRequests|started a thread on %{linkStart}an old version of a file%{linkEnd}');
      }
      if (isDiffDiscussion) {
        return isActive
          ? s__('MergeRequests|started a thread on %{linkStart}the diff%{linkEnd}')
          : s__(
              'MergeRequests|started a thread on %{linkStart}an old version of the diff%{linkEnd}',
            );
      }
      return s__('MergeRequests|started a thread');
    },
    isCommitLink() {
      const {
        for_commit: isForCommit,
        diff_discussion: isDiffDiscussion,
        commit_id: commitId,
      } = this.discussion;
      return isForCommit || (isDiffDiscussion && commitId);
    },
    truncatedCommitId() {
      return truncateSha(this.discussion.commit_id);
    },
    toggleClass() {
      return this.discussion.expanded ? 'expanded' : 'collapsed';
    },
    replies() {
      return this.notes.filter((note) => !note.system);
    },
  },
  methods: {
    ...mapActions(useNotes, ['toggleDiscussion']),
    toggleDiscussionHandler() {
      this.toggleDiscussion({ discussionId: this.discussion.id });
    },
    handleDiscussionLinkClick(event) {
      if (!this.navigateToDiffNote) return;
      event.preventDefault();
      this.navigateToDiffNote(this.discussion);
    },
  },
};
</script>

<template>
  <div class="discussion-header gl-flex gl-items-center">
    <div v-once class="timeline-avatar gl-shrink-0 gl-self-start">
      <gl-avatar-link
        v-if="author"
        :href="author.path"
        :data-user-id="author.id"
        :data-username="author.username"
        class="js-user-link"
      >
        <gl-avatar :src="author.avatar_url" :alt="author.name" :size="32" />
      </gl-avatar-link>
    </div>
    <div class="timeline-content gl-ml-3 gl-w-full" :class="toggleClass">
      <note-header :author="author" :created-at="firstNote.created_at" :note-id="firstNote.id">
        <gl-sprintf :message="headerMessage">
          <template #link="{ content } = {}">
            <a :href="discussion.discussion_path" @click="handleDiscussionLinkClick">
              <span v-if="isCommitLink" class="commit-sha">{{ truncatedCommitId }}</span>
              <template v-else>{{ content }}</template>
            </a>
          </template>
        </gl-sprintf>
      </note-header>
      <note-edited-text
        v-if="discussion.resolved"
        :edited-at="discussion.resolved_at"
        :edited-by="discussion.resolved_by"
        :action-text="resolvedText"
        class-name="discussion-headline-light js-discussion-headline gl-mt-1 gl-pl-3"
      />
      <ul class="gl-border-t -gl-mx-3 -gl-mb-3 gl-mt-4 gl-p-0 dark:gl-border-t-section">
        <toggle-replies-widget
          :collapsed="!discussion.expanded"
          :replies="replies"
          class="!gl-border-x-0"
          @toggle="toggleDiscussionHandler"
        />
      </ul>
    </div>
  </div>
</template>
