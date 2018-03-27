/* global CommentsStore */

import $ from 'jquery';
import Vue from 'vue';
import collapseIcon from '../icons/collapse_icon.svg';
import Notes from '../../notes';
import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';

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
  components: {
    userAvatarImage,
  },
  template: `
    <div class="diff-comment-avatar-holders"
      :class="discussionClassName"
      v-show="notesCount !== 0">
      <div v-if="!isVisible">
        <!-- FIXME: Pass an alt attribute here for accessibility -->
        <user-avatar-image
          v-for="note in notesSubset"
          :key="note.id"
          class="diff-comment-avatar js-diff-comment-avatar"
          @click.native="clickedAvatar($event)"
          :img-src="note.authorAvatar"
          :tooltip-text="getTooltipText(note)"
          :data-line-type="lineType"
          :size="19"
          data-html="true"
        />
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
  beforeDestroy() {
    this.addNoCommentClass();
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
    discussionClassName() {
      return `js-diff-avatars-${this.discussionId}`;
    },
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
      Notes.instance.onAddDiffNote(e);

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
        .toggleClass('no-comment-btn', notesCount > 0)
        .nextUntil('.js-avatar-container')
        .toggleClass('no-comment-btn', notesCount > 0);
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
    getTooltipText(note) {
      return `${note.authorName}: ${note.noteTruncated}`;
    },
  },
});

Vue.component('diff-note-avatars', DiffNoteAvatars);
