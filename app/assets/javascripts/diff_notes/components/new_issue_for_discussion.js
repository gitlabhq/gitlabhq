/* global CommentsStore */

import Vue from 'vue';

const NewIssueForDiscussion = Vue.extend({
  props: {
    discussionId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      discussions: CommentsStore.state,
    };
  },
  computed: {
    discussion() {
      return this.discussions[this.discussionId];
    },
    showButton() {
      if (this.discussion) return !this.discussion.isResolved();
      return false;
    },
  },
});

Vue.component('new-issue-for-discussion-btn', NewIssueForDiscussion);
