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
      mergeRequests: {},
      loadingMore: false,
    };
  },
  computed: {
    hasNextPage() {
      return this.mergeRequests.pageInfo?.hasNextPage;
    },
  },
  methods: {
    async loadMore() {
      this.loadingMore = true;

      await this.$apollo.queries.mergeRequests.fetchMore({
        variables: {
          ...this.variables,
          perPage: 10,
          afterCursor: this.mergeRequests.pageInfo?.endCursor,
        },
      });

      this.loadingMore = false;
    },
  },
  render() {
    return this.$scopedSlots.default({
      mergeRequests: this.mergeRequests.nodes || [],
      count: this.mergeRequests.count || 0,
      hasNextPage: this.hasNextPage,
      loadMore: this.loadMore,
      loadingMore: this.loadingMore,
    });
  },
};
</script>
