<script>
import { clamp } from 'lodash';
import { fetchPolicies } from '~/lib/graphql';
import { QUERIES } from '../constants';
import eventHub from '../event_hub';

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
          perPage: PER_PAGE,
          ...this.mergeRequestQueryVariables,
        };
      },
      error() {
        this.error = true;
      },
      result({ data }) {
        if (this.fromSubscription) {
          this.newMergeRequestIds = data?.currentUser?.mergeRequests?.nodes.reduce(
            (acc, mergeRequest) => {
              if (!this.currentMergeRequestIds.includes(mergeRequest.id)) {
                acc.push(mergeRequest.id);
              }

              return acc;
            },
            this.isVisible ? [] : this.newMergeRequestIds,
          );
          this.fromSubscription = false;
        } else {
          this.updateCurrentMergeRequestIds();
        }

        this.loading = false;
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
        return this.mergeRequestQueryVariables;
      },
      fetchPolicy: fetchPolicies.CACHE_ONLY,
      skip() {
        return this.hideCount;
      },
    },
    draftsCount: {
      fetchPolicy: fetchPolicies.NO_CACHE,
      query() {
        return QUERIES[this.query].countQuery;
      },
      update: (d) => d.currentUser?.mergeRequests?.count,
      skip() {
        return this.variables.draft == null || this.variables.draft === true;
      },
      variables() {
        return {
          ...this.variables,
          draft: true,
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
      required: false,
      default: () => ({}),
    },
    hideCount: {
      type: Boolean,
      required: false,
      default: false,
    },
    isVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      loading: true,
      mergeRequests: null,
      count: null,
      error: false,
      currentMergeRequestIds: [],
      newMergeRequestIds: [],
      fromSubscription: false,
      draftsCount: null,
    };
  },
  computed: {
    hasNextPage() {
      return this.mergeRequests?.pageInfo?.hasNextPage;
    },
    mergeRequestQueryVariables() {
      const variables = { ...this.variables };

      if (variables.draft) {
        delete variables.draft;
      }

      return variables;
    },
  },
  watch: {
    isVisible(newVal) {
      if (newVal) {
        this.updateCurrentMergeRequestIds();
      }
    },
  },
  mounted() {
    eventHub.$on('refetch.mergeRequests', this.refetchMergeRequests);
  },
  beforeDestroy() {
    eventHub.$off('refetch.mergeRequests', this.refetchMergeRequests);
  },
  methods: {
    refetchMergeRequests(type) {
      if (type !== this.query || !this.mergeRequests.nodes) return;

      this.fromSubscription = true;

      if (this.isVisible) {
        this.updateCurrentMergeRequestIds();
      }

      this.$apollo.queries.mergeRequests.refetch({
        perPage: clamp(
          Math.ceil(this.mergeRequests.nodes.length / PER_PAGE) * PER_PAGE,
          PER_PAGE,
          100,
        ),
      });

      if (!this.hideCount) {
        this.$apollo.queries.count.refetch();
      }
    },
    async loadMore() {
      this.loading = true;

      await this.$apollo.queries.mergeRequests.fetchMore({
        variables: {
          ...this.variables,
          perPage: PER_PAGE,
          afterCursor: this.mergeRequests?.pageInfo?.endCursor,
        },
      });
    },
    updateCurrentMergeRequestIds() {
      this.currentMergeRequestIds =
        this.mergeRequests?.nodes?.map((mergeRequest) => mergeRequest.id) ?? [];
    },
    resetNewMergeRequestIds() {
      this.updateCurrentMergeRequestIds();
      this.newMergeRequestIds = [];
    },
  },
  render() {
    return this.$scopedSlots.default({
      mergeRequests: this.mergeRequests?.nodes || [],
      newMergeRequestIds: this.newMergeRequestIds || [],
      count: this.count,
      hasNextPage: this.hasNextPage,
      loadMore: this.loadMore,
      loading: this.loading,
      error: this.error,
      resetNewMergeRequestIds: this.resetNewMergeRequestIds,
      draftsCount: this.draftsCount,
    });
  },
};
</script>
