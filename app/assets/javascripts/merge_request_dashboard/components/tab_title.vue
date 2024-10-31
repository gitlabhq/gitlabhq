<script>
import { GlBadge } from '@gitlab/ui';
import { QUERIES } from '../constants';

export default {
  components: { GlBadge },
  props: {
    title: {
      type: String,
      required: true,
    },
    queries: {
      type: Array,
      required: true,
    },
    tabKey: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      count: 0,
    };
  },
  async mounted() {
    this.fetchAllCounts();
  },
  methods: {
    async fetchAllCounts() {
      const counts = await Promise.all(
        this.queries.map(({ query, variables }) => this.fetchCount({ query, variables })),
      );

      this.count = counts.reduce((acc, { data }) => acc + data.currentUser.mergeRequests.count, 0);
      this.loading = false;
    },
    fetchCount({ query, variables }) {
      return this.$apollo.query({
        query: QUERIES[query].countQuery,
        variables,
        context: { batchKey: `MergeRequestTabsCounts_${this.tabKey}` },
      });
    },
  },
};
</script>

<template>
  <span>
    {{ title }}
    <gl-badge class="gl-tab-counter-badge" data-testid="tab-count">{{
      loading ? '-' : count
    }}</gl-badge>
  </span>
</template>
