((w) => {
  w.ResolveDiscussionBtn = Vue.extend({
    mixins: [
      ButtonMixins
    ],
    props: {
      discussionId: String,
      mergeRequestId: Number,
      namespacePath: String,
      projectPath: String,
    },
    data: function() {
      return {
        discussions: CommentsStore.state
      };
    },
    computed: {
      discussion: function () {
        return this.discussions[this.discussionId];
      },
      allResolved: function () {
        if (this.discussion) {
          return this.discussion.isResolved();
        }
      },
      buttonText: function () {
        if (this.allResolved) {
          return "Unresolve discussion";
        } else {
          return "Resolve discussion";
        }
      },
      loading: function () {
        if (this.discussion) {
          return this.discussion.loading;
        }
      }
    },
    methods: {
      resolve: function () {
        ResolveService.toggleResolveForDiscussion(this.namespace, this.mergeRequestId, this.discussionId);
      }
    }
  });
})(window);
