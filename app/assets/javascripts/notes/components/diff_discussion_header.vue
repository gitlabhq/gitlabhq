<script>
import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { escape } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { truncateSha } from '~/lib/utils/text_utility';
import { s__, __, sprintf } from '~/locale';
import { FILE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import NoteEditedText from './note_edited_text.vue';
import NoteHeader from './note_header.vue';

export default {
  name: 'DiffDiscussionHeader',
  components: {
    GlAvatar,
    GlAvatarLink,
    NoteEditedText,
    NoteHeader,
  },
  directives: {
    SafeHtml,
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
    lastNote() {
      return this.notes[this.notes.length - 1];
    },
    author() {
      return this.firstNote.author;
    },
    resolvedText() {
      return this.discussion.resolved_by_push ? __('Automatically resolved') : __('Resolved');
    },
    lastUpdatedBy() {
      return this.notes.length > 1 ? this.lastNote.author : null;
    },
    lastUpdatedAt() {
      return this.notes.length > 1 ? this.lastNote.created_at : null;
    },
    headerText() {
      const linkStart = `<a href="${escape(this.discussion.discussion_path)}">`;
      const linkEnd = '</a>';

      const { commit_id: commitId } = this.discussion;
      let commitDisplay = commitId;

      if (commitId) {
        commitDisplay = `<span class="commit-sha">${truncateSha(commitId)}</span>`;
      }

      const {
        for_commit: isForCommit,
        diff_discussion: isDiffDiscussion,
        active: isActive,
        position,
      } = this.discussion;

      let text = s__('MergeRequests|started a thread');
      if (isForCommit) {
        text = s__(
          'MergeRequests|started a thread on commit %{linkStart}%{commitDisplay}%{linkEnd}',
        );
      } else if (isDiffDiscussion && commitId) {
        text = isActive
          ? s__('MergeRequests|started a thread on commit %{linkStart}%{commitDisplay}%{linkEnd}')
          : s__(
              'MergeRequests|started a thread on an outdated change in commit %{linkStart}%{commitDisplay}%{linkEnd}',
            );
      } else if (isDiffDiscussion && position?.position_type === FILE_DIFF_POSITION_TYPE) {
        text = isActive
          ? s__('MergeRequests|started a thread on %{linkStart}a file%{linkEnd}')
          : s__('MergeRequests|started a thread on %{linkStart}an old version of a file%{linkEnd}');
      } else if (isDiffDiscussion) {
        text = isActive
          ? s__('MergeRequests|started a thread on %{linkStart}the diff%{linkEnd}')
          : s__(
              'MergeRequests|started a thread on %{linkStart}an old version of the diff%{linkEnd}',
            );
      }

      return sprintf(text, { commitDisplay, linkStart, linkEnd }, false);
    },
    toggleClass() {
      return this.discussion.expanded ? 'expanded' : 'collapsed';
    },
  },
  methods: {
    ...mapActions(['toggleDiscussion']),
    toggleDiscussionHandler() {
      this.toggleDiscussion({ discussionId: this.discussion.id });
    },
  },
};
</script>

<template>
  <div class="discussion-header gl-display-flex gl-align-items-center">
    <div v-once class="timeline-avatar gl-align-self-start gl-flex-shrink-0 gl-flex-shrink">
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
    <div class="timeline-content gl-w-full gl-ml-3" :class="toggleClass">
      <note-header
        :author="author"
        :created-at="firstNote.created_at"
        :note-id="firstNote.id"
        :include-toggle="true"
        :expanded="discussion.expanded"
        @toggleHandler="toggleDiscussionHandler"
      >
        <span v-safe-html="headerText"></span>
      </note-header>
      <note-edited-text
        v-if="discussion.resolved"
        :edited-at="discussion.resolved_at"
        :edited-by="discussion.resolved_by"
        :action-text="resolvedText"
        class-name="discussion-headline-light js-discussion-headline gl-pl-3"
      />
      <note-edited-text
        v-else-if="lastUpdatedAt"
        :edited-at="lastUpdatedAt"
        :edited-by="lastUpdatedBy"
        :action-text="__('Last updated')"
        class-name="discussion-headline-light js-discussion-headline gl-pl-3"
      />
    </div>
  </div>
</template>
