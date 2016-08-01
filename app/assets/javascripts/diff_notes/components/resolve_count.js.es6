((w) => {
  w.ResolveCount = Vue.extend({
    props: {
      loggedOut: Boolean
    },
    data: function () {
      return {
        discussions: CommentsStore.state,
        loading: false
      };
    },
    computed: {
      resolved: function () {
        let resolvedCount = 0;

        for (const discussionId in this.discussions) {
          const discussion = this.discussions[discussionId];

          if (discussion.isResolved()) {
            resolvedCount++;
          }
        }

        return resolvedCount;
      },
      discussionCount: function () {
        return Object.keys(this.discussions).length;
      },
      allResolved: function () {
        return this.resolved === this.discussionCount;
      }
    }
  });
})(window);
