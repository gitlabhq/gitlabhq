/* global CommentsStore */

import $ from 'jquery';
import Vue from 'vue';

const CommentAndResolveBtn = Vue.extend({
  props: {
    discussionId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      textareaIsEmpty: true,
      discussion: {},
    };
  },
  computed: {
    showButton() {
      if (this.discussion) {
        return this.discussion.isResolvable();
      }

      return false;
    },
    isDiscussionResolved() {
      return this.discussion.isResolved();
    },
    buttonText() {
      if (this.isDiscussionResolved) {
        if (this.textareaIsEmpty) {
          return 'Unresolve discussion';
        }

        return 'Comment & unresolve discussion';
      }

      if (this.textareaIsEmpty) {
        return 'Resolve discussion';
      }

      return 'Comment & resolve discussion';
    },
  },
  created() {
    if (this.discussionId) {
      this.discussion = CommentsStore.state[this.discussionId];
    }
  },
  mounted() {
    if (!this.discussionId) return;

    const $textarea = $(
      `.js-discussion-note-form[data-discussion-id=${this.discussionId}] .note-textarea`,
    );
    this.textareaIsEmpty = $textarea.val() === '';

    $textarea.on('input.comment-and-resolve-btn', () => {
      this.textareaIsEmpty = $textarea.val() === '';
    });
  },
  destroyed() {
    if (!this.discussionId) return;

    $(`.js-discussion-note-form[data-discussion-id=${this.discussionId}] .note-textarea`).off(
      'input.comment-and-resolve-btn',
    );
  },
});

Vue.component('comment-and-resolve-btn', CommentAndResolveBtn);
