<script>
import { QUERIES } from '../constants';

const PER_PAGE = 20;

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
      context: {
        batchKey: 'MergeRequestListsCounts',
      },
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
      skip() {
        return this.hideCount;
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
    hideCount: {
      type: Boolean,
      required: false,
      default: false,
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
