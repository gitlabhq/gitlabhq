/* eslint-disable comma-dangle, object-shorthand, func-names, no-param-reassign */
/* global DiscussionMixins */
/* global CommentsStore */
const Vue = require('vue');

((w) => {
  w.ResolveCount = Vue.extend({
    mixins: [DiscussionMixins],
    props: {
      loggedOut: Boolean
    },
    data: function () {
      return {
        discussions: CommentsStore.state
      };
    },
    computed: {
      allResolved: function () {
        return this.resolvedDiscussionCount === this.discussionCount;
      },
      resolvedCountText() {
        return this.discussionCount === 1 ? 'discussion' : 'discussions';
      }
    }
  });
})(window);
