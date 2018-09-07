/* global CommentsStore */
/* global ResolveService */

import Vue from 'vue';

const ResolveDiscussionBtn = Vue.extend({
  props: {
    discussionId: {
      type: String,
      required: true,
    },
    mergeRequestId: {
      type: Number,
      required: true,
    },
    canResolve: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
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
      if (this.discussion) {
        return this.discussion.isResolved();
      }

      return false;
    },
    buttonText() {
      if (this.isDiscussionResolved) {
        return 'Unresolve discussion';
      }

      return 'Resolve discussion';
    },
    loading() {
      if (this.discussion) {
        return this.discussion.loading;
      }

      return false;
    },
  },
  created() {
    CommentsStore.createDiscussion(this.discussionId, this.canResolve);

    this.discussion = CommentsStore.state[this.discussionId];
  },
  methods: {
    resolve() {
      ResolveService.toggleResolveForDiscussion(this.mergeRequestId, this.discussionId);
    },
  },
});

Vue.component('resolve-discussion-btn', ResolveDiscussionBtn);
