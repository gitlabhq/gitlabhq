<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { createAlert } from '~/alert';
import { number } from '~/lib/utils/unit_format';
import { __, s__ } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import usageTrendsCountQuery from '../graphql/queries/usage_trends_count.query.graphql';

const defaultPrecision = 0;

export default {
  name: 'UsageCounts',
  components: {
    GlSkeletonLoader,
    GlSingleStat,
    PageHeading,
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
        createAlert({
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
    loadCountsError: __('Could not load usage counts. Please refresh the page to try again.'),
    pageTitle: __('Usage trends'),
  },
};
</script>

<template>
  <div>
    <page-heading :heading="$options.i18n.pageTitle" />
    <div class="gl-my-6 gl-flex gl-flex-col gl-items-start md:gl-flex-row">
      <gl-skeleton-loader v-if="$apollo.queries.counts.loading" />
      <template v-else>
        <gl-single-stat
          v-for="count in counts"
          :key="count.key"
          class="gl-my-4 gl-pr-9 md:gl-mb-0 md:gl-mt-0"
          :value="`${count.value}`"
          :title="count.label"
          :should-animate="true"
        />
      </template>
    </div>
  </div>
</template>
