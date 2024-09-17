<script>
import reviewerQuery from '../queries/reviewer.query.graphql';
import reviewerCountQuery from '../queries/reviewer_count.query.graphql';
import assigneeQuery from '../queries/assignee.query.graphql';
import assigneeCountQuery from '../queries/assignee_count.query.graphql';
import assigneeOrReviewerQuery from '../queries/assignee_or_reviewer.query.graphql';
import assigneeOrReviewerCountQuery from '../queries/assignee_or_reviewer_count.query.graphql';

const PER_PAGE = 20;

const QUERIES = {
  reviewRequestedMergeRequests: { dataQuery: reviewerQuery, countQuery: reviewerCountQuery },
  assignedMergeRequests: { dataQuery: assigneeQuery, countQuery: assigneeCountQuery },
  assigneeOrReviewerMergeRequests: {
    dataQuery: assigneeOrReviewerQuery,
    countQuery: assigneeOrReviewerCountQuery,
  },
};

export default {
  apollo: {
    mergeRequests: {
      query() {
        return QUERIES[this.query].dataQuery;
      },
      update(d) {
        return d.currentUser?.mergeRequests || {};
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
    count: {
      query() {
        return QUERIES[this.query].countQuery;
      },
      update(d) {
        return d.currentUser?.mergeRequests?.count;
      },
      variables() {
        return {
          ...this.variables,
          perPage: PER_PAGE,
        };
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
      count: null,
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
      count: this.count,
      hasNextPage: this.hasNextPage,
      loadMore: this.loadMore,
      loading: this.isLoading,
      error: this.error,
    });
  },
};
</script>
