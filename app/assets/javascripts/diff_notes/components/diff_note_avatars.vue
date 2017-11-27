<script>
/* global CommentsStore */
/* global notes */

import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  props: {
    discussionId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showCollapseButton: false,
      lineType: '',
      storeState: CommentsStore.state,
      shownAvatars: 3,
    };
  },
  components: {
    Icon,
    UserAvatarImage,
  },
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
        return this.n__('%d more comment', '%d more comments', this.extraComments);
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
    extraComments() {
      return this.notesCount - this.shownAvatars;
    },
    moreText() {
      const plusSign = this.notesCount < 100 ? '+' : '';

      return `${plusSign}${this.extraComments}`;
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
      this.showCollapseButton = $(`.diffs .notes[data-discussion-id="${this.discussion.id}"]`).is(':visible');
    },
    getTooltipText(note) {
      return `${note.authorName}: ${note.noteTruncated}`;
    },
  },
};
</script>

<template>
  <div class="diff-comment-avatar-holders"
    :class="discussionClassName"
    v-show="notesCount !== 0">
    <button
      v-if="showCollapseButton"
      class="diff-notes-collapse js-diff-comment-avatar"
      type="button"
      aria-label="Show comments"
      :data-line-type="lineType"
      @click="clickedAvatar($event)"
    >
      <icon
        name="collapse"
        :size="12"
      />
    </button>
    <div v-else>
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
  </div>
</template>
