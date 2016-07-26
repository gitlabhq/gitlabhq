((w) => {
  w.ResolveCommentBtn = Vue.extend({
    props: {
      discussionId: String
    },
    computed: {
      isDiscussionResolved: function () {
        const notes = CommentsStore.notesForDiscussion(this.discussionId),
              discussion = CommentsStore.state[this.discussionId];
        let allResolved = true;

        for (const noteId of notes) {
          const note = discussion[noteId];

          if (!note.resolved) {
            allResolved = false;
          }
        }

        return allResolved;
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
}(window));
