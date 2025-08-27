<script>
import setReviewersMutation from './queries/set_reviewers.mutation.graphql';

export default {
  inject: ['projectPath', 'issuableIid'],
  props: {
    selectedReviewers: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  methods: {
    async updateReviewers() {
      this.loading = true;

      await this.$apollo.mutate({
        mutation: setReviewersMutation,
        variables: {
          reviewerUsernames: this.selectedReviewers,
          projectPath: this.projectPath,
          iid: this.issuableIid,
        },
      });

      this.loading = false;
    },
  },
  render() {
    return this.$scopedSlots.default({
      loading: this.loading,
      updateReviewers: this.updateReviewers,
    });
  },
};
</script>
