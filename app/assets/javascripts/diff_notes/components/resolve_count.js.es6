/* eslint-disable */
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
      }
    }
  });
})(window);
