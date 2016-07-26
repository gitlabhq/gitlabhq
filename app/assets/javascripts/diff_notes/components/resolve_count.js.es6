((w) => {
  w.ResolveCount = Vue.extend({
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
          const comments = this.discussions[discussionId];
          let resolved = true;

          for (const noteId in comments) {
            const commentResolved = comments[noteId].resolved;

            if (!commentResolved) {
              resolved = false;
            }
          }

          if (resolved) {
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
}(window));
