((w) => {
  w.ResolveAll = Vue.extend({
    props: {
      discussionId: String,
      namespace: String,
    },
    data: function() {
      return {
        comments: CommentsStore.state,
        loadingObject: CommentsStore.loading,
      };
    },
    computed: {
      allResolved: function () {
        let isResolved = true;
        for (const noteId in this.comments[this.discussionId]) {
          const resolved = this.comments[this.discussionId][noteId];

          if (!resolved) {
            isResolved = false;
          }
        }
        return isResolved;
      },
      buttonText: function () {
        if (this.allResolved) {
          return "Unresolve discussion";
        } else {
          return "Resolve discussion";
        }
      },
      loading: function () {
        return this.loadingObject[this.discussionId];
      }
    },
    methods: {
      resolve: function () {
        ResolveService
          .resolveAll(this.namespace, this.discussionId, this.allResolved);
      }
    }
  });
}(window));
