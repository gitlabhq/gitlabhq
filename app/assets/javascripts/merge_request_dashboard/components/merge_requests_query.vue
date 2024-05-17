<script>
import reviewerQuery from '../queries/reviewer.query.graphql';
import assigneeQuery from '../queries/assignee.query.graphql';

export default {
  apollo: {
    mergeRequests: {
      query() {
        return this.query === 'reviewRequestedMergeRequests' ? reviewerQuery : assigneeQuery;
      },
      update(d) {
        return d.currentUser?.[this.query] || {};
      },
      variables() {
        return {
          ...this.variables,
          perPage: 3,
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
          perPage: 10,
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
    });
  },
};
</script>
