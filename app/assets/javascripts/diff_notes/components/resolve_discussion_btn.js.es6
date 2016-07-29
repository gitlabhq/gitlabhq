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
      allResolved: function () {
        return this.discussions[this.discussionId].isResolved();
      },
      buttonText: function () {
        if (this.allResolved) {
          return "Unresolve discussion";
        } else {
          return "Resolve discussion";
        }
      },
      loading: function () {
        return this.discussions[this.discussionId].loading;
      }
    },
    methods: {
      resolve: function () {
        ResolveService.toggleResolveForDiscussion(this.namespace, this.mergeRequestId, this.discussionId);
      }
    }
  });
})(window);
