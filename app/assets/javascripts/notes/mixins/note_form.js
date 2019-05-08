export default {
  data() {
    return {
      showBatchCommentsActions: false,
    };
  },
  methods: {
    handleKeySubmit() {
      this.handleUpdate();
    },
    handleUpdate(shouldResolve) {
      const beforeSubmitDiscussionState = this.discussionResolved;
      this.isSubmitting = true;

      this.$emit('handleFormUpdate', this.updatedNoteBody, this.$refs.editNoteForm, () => {
        this.isSubmitting = false;

        if (this.shouldToggleResolved(shouldResolve, beforeSubmitDiscussionState)) {
          this.resolveHandler(beforeSubmitDiscussionState);
        }
      });
    },
  },
};
