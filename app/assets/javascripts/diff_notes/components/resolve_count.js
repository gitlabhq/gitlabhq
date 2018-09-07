/* global CommentsStore */

import Vue from 'vue';

import DiscussionMixins from '../mixins/discussion';

window.ResolveCount = Vue.extend({
  mixins: [DiscussionMixins],
  props: {
    loggedOut: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      discussions: CommentsStore.state,
    };
  },
  computed: {
    allResolved() {
      return this.resolvedDiscussionCount === this.discussionCount;
    },
    resolvedCountText() {
      return this.discussionCount === 1 ? 'discussion' : 'discussions';
    },
  },
});
