((w) => {
  w.ResolveCommentBtn = Vue.extend({
    props: {
      discussionId: String
    },
    computed: {
      isDiscussionResolved: function () {
        const discussion = CommentsStore.state[this.discussionId],
              notes = CommentsStore.notesForDiscussion(this.discussionId);

        return discussion.isResolved();
      },
      buttonText: function () {
        if (this.isDiscussionResolved) {
          return "Comment & unresolve discussion";
        } else {
          return "Comment & resolve discussion";
        }
      }
    }
  });
})(window);
