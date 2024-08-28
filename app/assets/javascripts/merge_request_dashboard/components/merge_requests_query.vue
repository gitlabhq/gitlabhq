<script>
import reviewerQuery from '../queries/reviewer.query.graphql';
import assigneeQuery from '../queries/assignee.query.graphql';
import assigneeOrReviewerQuery from '../queries/assignee_or_reviewer.query.graphql';

const PER_PAGE = 20;

const QUERIES = {
  reviewRequestedMergeRequests: reviewerQuery,
  assignedMergeRequests: assigneeQuery,
  assigneeOrReviewerMergeRequests: assigneeOrReviewerQuery,
};

export default {
  apollo: {
    mergeRequests: {
      query() {
        return QUERIES[this.query];
      },
      update(d) {
        return d.currentUser?.[this.query] || {};
      },
      variables() {
        return {
          ...this.variables,
          perPage: PER_PAGE,
        };
      },
      error() {
        this.error = true;
      },
    },
  },
  props: {
    query: {
      type: String,
      required: true,
    },
    variables: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      mergeRequests: null,
      error: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.mergeRequests.loading;
    },
    hasNextPage() {
      return this.mergeRequests?.pageInfo?.hasNextPage;
    },
  },
  methods: {
    async loadMore() {
      await this.$apollo.queries.mergeRequests.fetchMore({
        variables: {
          ...this.variables,
          perPage: PER_PAGE,
          afterCursor: this.mergeRequests?.pageInfo?.endCursor,
        },
      });
    },
  },
  render() {
    return this.$scopedSlots.default({
      mergeRequests: this.mergeRequests?.nodes || [],
      count: this.mergeRequests ? this.mergeRequests.count : null,
      hasNextPage: this.hasNextPage,
      loadMore: this.loadMore,
      loading: this.isLoading,
      error: this.error,
    });
  },
};
</script>
