<script>
import * as Sentry from '~/sentry/wrapper';
import { s__ } from '~/locale';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import MetricCard from '~/analytics/shared/components/metric_card.vue';
import instanceStatisticsCountQuery from '../graphql/queries/instance_statistics_count.query.graphql';

const defaultPrecision = 0;

export default {
  name: 'InstanceCounts',
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
      query: instanceStatisticsCountQuery,
      update(data) {
        return Object.entries(data).map(([key, obj]) => {
          const label = this.$options.i18n.labels[key];
          const formatter = getFormatter(SUPPORTED_FORMATS.number);
          const value = obj.nodes?.length ? formatter(obj.nodes[0].count, defaultPrecision) : null;

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
      users: s__('InstanceStatistics|Users'),
      projects: s__('InstanceStatistics|Projects'),
      groups: s__('InstanceStatistics|Groups'),
      issues: s__('InstanceStatistics|Issues'),
      mergeRequests: s__('InstanceStatistics|Merge Requests'),
      pipelines: s__('InstanceStatistics|Pipelines'),
    },
    loadCountsError: s__('Could not load instance counts. Please refresh the page to try again.'),
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
