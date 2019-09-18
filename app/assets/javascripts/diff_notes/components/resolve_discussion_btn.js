/* eslint-disable no-else-return */
/* global CommentsStore */
/* global ResolveService */

import Vue from 'vue';
import { __ } from '~/locale';

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
      } else {
        return false;
      }
    },
    isDiscussionResolved() {
      if (this.discussion) {
        return this.discussion.isResolved();
      } else {
        return false;
      }
    },
    buttonText() {
      if (this.isDiscussionResolved) {
        return __('Unresolve discussion');
      } else {
        return __('Resolve discussion');
      }
    },
    loading() {
      if (this.discussion) {
        return this.discussion.loading;
      } else {
        return false;
      }
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
