/* global CommentsStore */
/* global notes */

import Vue from 'vue';
import collapseIcon from '../icons/collapse_icon.svg';

const DiffNoteAvatars = Vue.extend({
  props: ['discussionId'],
  data() {
    return {
      isVisible: false,
      lineType: '',
      storeState: CommentsStore.state,
      shownAvatars: 3,
      collapseIcon,
    };
  },
  template: `
    <div class="diff-comment-avatar-holders"
      v-show="notesCount !== 0">
      <div v-if="!isVisible">
        <img v-for="note in notesSubset"
          class="avatar diff-comment-avatar has-tooltip js-diff-comment-avatar"
          width="19"
          height="19"
          role="button"
          data-container="body"
          data-placement="top"
          data-html="true"
          :data-line-type="lineType"
          :title="note.authorName + ': ' + note.noteTruncated"
          :src="note.authorAvatar"
          @click="clickedAvatar($event)" />
        <span v-if="notesCount > shownAvatars"
          class="diff-comments-more-count has-tooltip js-diff-comment-avatar"
          data-container="body"
          data-placement="top"
          ref="extraComments"
          role="button"
          :data-line-type="lineType"
          :title="extraNotesTitle"
          @click="clickedAvatar($event)">{{ moreText }}</span>
      </div>
      <button class="diff-notes-collapse js-diff-comment-avatar"
        type="button"
        aria-label="Show comments"
        :data-line-type="lineType"
        @click="clickedAvatar($event)"
        v-if="isVisible"
        v-html="collapseIcon">
      </button>
    </div>
  `,
  mounted() {
    this.$nextTick(() => {
      this.addNoCommentClass();
      this.setDiscussionVisible();

      this.lineType = $(this.$el).closest('.diff-line-num').hasClass('old_line') ? 'old' : 'new';
    });

    $(document).on('toggle.comments', () => {
      this.$nextTick(() => {
        this.setDiscussionVisible();
      });
    });
  },
  destroyed() {
    $(document).off('toggle.comments');
  },
  watch: {
    storeState: {
      handler() {
        this.$nextTick(() => {
          $('.has-tooltip', this.$el).tooltip('fixTitle');

          // We need to add/remove a class to an element that is outside the Vue instance
          this.addNoCommentClass();
        });
      },
      deep: true,
    },
  },
  computed: {
    notesSubset() {
      let notes = [];

      if (this.discussion) {
        notes = Object.keys(this.discussion.notes)
          .slice(0, this.shownAvatars)
          .map(noteId => this.discussion.notes[noteId]);
      }

      return notes;
    },
    extraNotesTitle() {
      if (this.discussion) {
        const extra = this.discussion.notesCount() - this.shownAvatars;

        return `${extra} more comment${extra > 1 ? 's' : ''}`;
      }

      return '';
    },
    discussion() {
      return this.storeState[this.discussionId];
    },
    notesCount() {
      if (this.discussion) {
        return this.discussion.notesCount();
      }

      return 0;
    },
    moreText() {
      const plusSign = this.notesCount < 100 ? '+' : '';

      return `${plusSign}${this.notesCount - this.shownAvatars}`;
    },
  },
  methods: {
    clickedAvatar(e) {
      notes.onAddDiffNote(e);

      // Toggle the active state of the toggle all button
      this.toggleDiscussionsToggleState();

      this.$nextTick(() => {
        this.setDiscussionVisible();

        $('.has-tooltip', this.$el).tooltip('fixTitle');
        $('.has-tooltip', this.$el).tooltip('hide');
      });
    },
    addNoCommentClass() {
      const notesCount = this.notesCount;

      $(this.$el).closest('.js-avatar-container')
        .toggleClass('js-no-comment-btn', notesCount > 0)
        .nextUntil('.js-avatar-container')
        .toggleClass('js-no-comment-btn', notesCount > 0);
    },
    toggleDiscussionsToggleState() {
      const $notesHolders = $(this.$el).closest('.code').find('.notes_holder');
      const $visibleNotesHolders = $notesHolders.filter(':visible');
      const $toggleDiffCommentsBtn = $(this.$el).closest('.diff-file').find('.js-toggle-diff-comments');

      $toggleDiffCommentsBtn.toggleClass('active', $notesHolders.length === $visibleNotesHolders.length);
    },
    setDiscussionVisible() {
      this.isVisible = $(`.diffs .notes[data-discussion-id="${this.discussion.id}"]`).is(':visible');
    },
  },
});

Vue.component('diff-note-avatars', DiffNoteAvatars);
