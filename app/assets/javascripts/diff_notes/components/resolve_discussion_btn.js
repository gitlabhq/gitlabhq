/* eslint-disable object-shorthand, func-names, space-before-function-paren, comma-dangle, no-else-return, quotes, max-len */
/* global CommentsStore */
/* global ResolveService */

import Vue from 'vue';

const ResolveDiscussionBtn = Vue.extend({
  props: {
    discussionId: String,
    mergeRequestId: Number,
    canResolve: Boolean,
  },
  data: function() {
    return {
      discussion: {},
    };
  },
  computed: {
    showButton: function () {
      if (this.discussion) {
        return this.discussion.isResolvable();
      } else {
        return false;
      }
    },
    isDiscussionResolved: function () {
      if (this.discussion) {
        return this.discussion.isResolved();
      } else {
        return false;
      }
    },
    buttonText: function () {
      if (this.isDiscussionResolved) {
        return "Unresolve discussion";
      } else {
        return "Resolve discussion";
      }
    },
    loading: function () {
      if (this.discussion) {
        return this.discussion.loading;
      } else {
        return false;
      }
    }
  },
  created: function () {
    CommentsStore.createDiscussion(this.discussionId, this.canResolve);

    this.discussion = CommentsStore.state[this.discussionId];
  },
  methods: {
    resolve: function () {
      ResolveService.toggleResolveForDiscussion(this.mergeRequestId, this.discussionId);
    }
  },
});

Vue.component('resolve-discussion-btn', ResolveDiscussionBtn);
