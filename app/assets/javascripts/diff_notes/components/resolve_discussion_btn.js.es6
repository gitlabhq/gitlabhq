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
      canResolve: Boolean,
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
      showButton: function () {
        if (this.discussion) {
          return this.discussion.isResolvable();
        } else {
          return undefined;
        }
      },
      allResolved: function () {
        if (this.discussion) {
          return this.discussion.isResolved();
        } else {
          return undefined;
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
        } else {
          return undefined;
        }
      }
    },
    methods: {
      resolve: function () {
        ResolveService.toggleResolveForDiscussion(this.namespace, this.mergeRequestId, this.discussionId);
      }
    },
    created: function () {
      CommentsStore.createDiscussion(this.discussionId, this.canResolve);
    }
  });
})(window);
