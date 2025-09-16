<script>
import { GlBadge } from '@gitlab/ui';
import { camelCase } from 'lodash';
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
  },
  data() {
    return {
      loading: true,
      count: 0,
    };
  },
  created() {
    this.fetchAllCounts();
  },
  methods: {
    fetchAllCounts() {
      this.queries.forEach(({ query, variables }, index) => {
        const countVariables = { ...variables };

        if (countVariables.draft) {
          delete countVariables.draft;
        }

        this.$apollo.addSmartQuery(`${query}_${index}`, {
          query: QUERIES[query].countQuery,
          variables: countVariables,
          manual: true,
          context: { batchKey: `MergeRequestTabsCounts_${camelCase(this.title)}` },
          result({ data }) {
            if (data?.currentUser) {
              this.count += data?.currentUser?.mergeRequests?.count ?? 0;

              this.loading = false;
            }
          },
        });
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
