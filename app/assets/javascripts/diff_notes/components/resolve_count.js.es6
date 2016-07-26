((w) => {
  w.ResolveCount = Vue.extend({
    data: function () {
      return {
        comments: CommentsStore.state,
        loading: false
      };
    },
    computed: {
      resolved: function () {
        let resolvedCount = 0;

        for (const discussionId in this.comments) {
          const comments = this.comments[discussionId];
          let resolved = true;

          for (const noteId in comments) {
            const commentResolved = comments[noteId];

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
      commentsCount: function () {
        return Object.keys(this.comments).length;
      },
      allResolved: function () {
        return this.resolved === this.commentsCount;
      }
    }
  });
}(window));
