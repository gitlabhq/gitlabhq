((w) => {
  w.ResolveDiscussionBtn = Vue.extend({
    props: {
      discussionId: String,
      mergeRequestId: Number,
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
          return false;
        }
      },
      isDiscussionResolved: function () {
        if (this.discussion) {
          return this.discussion.isResolved();
        } else {
          return false;
        }
      },
      buttonText: function () {
        if (this.isDiscussionResolved) {
          return "Unresolve discussion";
        } else {
          return "Resolve discussion";
        }
      },
      loading: function () {
        if (this.discussion) {
          return this.discussion.loading;
        } else {
          return false;
        }
      }
    },
    methods: {
      resolve: function () {
        ResolveService.toggleResolveForDiscussion(this.projectPath, this.mergeRequestId, this.discussionId);
      }
    },
    created: function () {
      CommentsStore.createDiscussion(this.discussionId, this.canResolve);
    }
  });
})(window);
