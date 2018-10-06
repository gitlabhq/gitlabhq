import { mapGetters, mapState } from 'vuex';

export default {
  computed: {
    ...mapState({
      withBatchComments: state => state.batchComments && state.batchComments.withBatchComments,
    }),
    ...mapGetters('batchComments', ['hasDrafts']),
  },
  methods: {
    shouldBeResolved(resolveStatus) {
      if (this.withBatchComments) {
        return (
          (this.discussionResolved && !this.isUnresolving) ||
          (!this.discussionResolved && this.isResolving)
        );
      }

      return resolveStatus;
    },
    handleUpdate(resolveStatus) {
      const beforeSubmitDiscussionState = this.discussionResolved;
      this.isSubmitting = true;

      const shouldBeResolved = this.shouldBeResolved(resolveStatus) !== beforeSubmitDiscussionState;

      this.$emit('handleFormUpdate', this.updatedNoteBody, this.$refs.editNoteForm, () => {
        this.isSubmitting = false;

        if (resolveStatus || (shouldBeResolved && this.withBatchComments)) {
          this.resolveHandler(beforeSubmitDiscussionState); // this will toggle the state
        }
      });
    },
    handleAddToReview() {
      // check if draft should resolve discussion
      const shouldResolve =
        (this.discussionResolved && !this.isUnresolving) ||
        (!this.discussionResolved && this.isResolving);
      this.isSubmitting = true;

      this.$emit('handleFormUpdateAddToReview', this.updatedNoteBody, shouldResolve);
    },
  },
};
