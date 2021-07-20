<script>
import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import createFlash from '~/flash';
import { number } from '~/lib/utils/unit_format';
import { s__ } from '~/locale';
import usageTrendsCountQuery from '../graphql/queries/usage_trends_count.query.graphql';

const defaultPrecision = 0;

export default {
  name: 'UsageCounts',
  components: {
    GlSkeletonLoading,
    GlSingleStat,
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
        createFlash({
          message: this.$options.i18n.loadCountsError,
          captureError: true,
          error,
        });
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
  <div>
    <h2>
      {{ __('Usage Trends') }}
    </h2>
    <div
      class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-my-6 gl-align-items-flex-start"
    >
      <gl-skeleton-loading v-if="$apollo.queries.counts.loading" />
      <template v-else>
        <gl-single-stat
          v-for="count in counts"
          :key="count.key"
          class="gl-pr-9 gl-my-4 gl-md-mt-0 gl-md-mb-0"
          :value="`${count.value}`"
          :title="count.label"
          :should-animate="true"
        />
      </template>
    </div>
  </div>
</template>
