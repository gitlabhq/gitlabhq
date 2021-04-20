<script>
import * as Sentry from '@sentry/browser';
import MetricCard from '~/analytics/shared/components/metric_card.vue';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { number } from '~/lib/utils/unit_format';
import { s__ } from '~/locale';
import usageTrendsCountQuery from '../graphql/queries/usage_trends_count.query.graphql';

const defaultPrecision = 0;

export default {
  name: 'UsageCounts',
  components: {
    MetricCard,
  },
  data() {
    return {
      counts: [],
    };
  },
  apollo: {
    counts: {
      query: usageTrendsCountQuery,
      update(data) {
        return Object.entries(data).map(([key, obj]) => {
          const label = this.$options.i18n.labels[key];
          const value = obj.nodes?.length ? number(obj.nodes[0].count, defaultPrecision) : null;

          return {
            key,
            value,
            label,
          };
        });
      },
      error(error) {
        createFlash(this.$options.i18n.loadCountsError);
        Sentry.captureException(error);
      },
    },
  },
  i18n: {
    labels: {
      users: s__('UsageTrends|Users'),
      projects: s__('UsageTrends|Projects'),
      groups: s__('UsageTrends|Groups'),
      issues: s__('UsageTrends|Issues'),
      mergeRequests: s__('UsageTrends|Merge requests'),
      pipelines: s__('UsageTrends|Pipelines'),
    },
    loadCountsError: s__('Could not load usage counts. Please refresh the page to try again.'),
  },
};
</script>

<template>
  <metric-card
    :title="__('Usage Trends')"
    :metrics="counts"
    :is-loading="$apollo.queries.counts.loading"
    class="gl-mt-4"
  />
</template>
