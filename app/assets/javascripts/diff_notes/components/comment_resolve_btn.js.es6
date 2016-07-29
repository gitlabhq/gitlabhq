((w) => {
  w.CommentAndResolveBtn = Vue.extend({
    props: {
      discussionId: String,
      textareaVal: String
    },
    computed: {
      isDiscussionResolved: function () {
        const discussion = CommentsStore.state[this.discussionId];

        return discussion.isResolved();
      },
      buttonText: function () {
        const textVal = this.textareaVal;

        if (this.isDiscussionResolved) {
          if (textVal === '') {
            return "Unresolve discussion";
          } else {
            return "Comment & unresolve discussion";
          }
        } else {
          if (textVal === '') {
            return "Resolve discussion";
          } else {
            return "Comment & resolve discussion";
          }
        }
      }
    },
    ready: function () {
      const $textarea = $(`#new-discussion-note-form-${this.discussionId} .note-textarea`);
      this.textareaVal = $textarea.val();

      $textarea.on('input', () => {
        this.textareaVal = $textarea.val();
      });
    },
    destroyed: function () {
      $(`#new-discussion-note-form-${this.discussionId} .note-textarea`).off('input');
    }
  });
})(window);
