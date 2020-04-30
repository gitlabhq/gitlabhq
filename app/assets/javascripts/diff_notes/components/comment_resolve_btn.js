/* global CommentsStore */

import $ from 'jquery';
import Vue from 'vue';
import { __ } from '~/locale';

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
      if (this.textareaIsEmpty) {
        return this.isDiscussionResolved ? __('Unresolve thread') : __('Resolve thread');
      }
      return this.isDiscussionResolved
        ? __('Comment & unresolve thread')
        : __('Comment & resolve thread');
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
