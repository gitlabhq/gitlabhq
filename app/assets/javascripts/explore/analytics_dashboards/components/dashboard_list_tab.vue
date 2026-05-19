<script>
import { GlSkeletonLoader, GlTab, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import DashboardsList from '~/vue_shared/components/dashboards_list/dashboards_list.vue';
import EmptyState from '~/vue_shared/components/dashboards_list/empty_state.vue';
import { getDashboardIdFromGraphQLId } from '../utils';
import getDashboardsQuery from '../graphql/get_dashboards.query.graphql';

export default {
  name: 'DashboardListTab',
  components: { DashboardsList, EmptyState, GlSkeletonLoader, GlTab, GlAlert },
  inject: ['exploreAnalyticsDashboardsPath'],
  props: {
    title: {
      type: String,
      required: true,
    },
    srText: {
      type: String,
      required: true,
    },
    scope: {
      type: String,
      required: false,
      default: null,
    },
    search: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      dashboards: [],
      errorText: '',
    };
  },
  computed: {
    isLoading() {
      return Boolean(this.$apollo.queries.dashboards?.loading);
    },
    hasError() {
      return this.errorText !== '';
    },
    hasDashboards() {
      return Boolean(this.dashboards.length);
    },
    enrichedDashboards() {
      // Enriches the raw results with any FE computed fields we need
      return this.dashboards.map((data) => ({
        ...data,
        dashboardUrl: joinPaths(
          this.exploreAnalyticsDashboardsPath,
          String(getDashboardIdFromGraphQLId(data.id)),
        ),
        isStarred: false,
      }));
    },
  },
  apollo: {
    dashboards: {
      query: getDashboardsQuery,
      variables() {
        return {
          search: this.search,
          scope: this.scope || undefined,
        };
      },
      update({ customDashboards }) {
        return customDashboards?.nodes;
      },
      error(err) {
        this.errorText = s__(
          'AnalyticsDashboards|Failed to load dashboards list. Please try again.',
        );
        Sentry.captureException(err);
      },
    },
  },
};
</script>
<template>
  <gl-tab :title="title" :tab-count="dashboards.length" :tab-count-sr-text="srText">
    <gl-skeleton-loader v-if="isLoading" size="lg" class="gl-mt-4" />
    <gl-alert v-else-if="hasError" variant="danger" :dismissible="false" class="gl-mt-4">{{
      errorText
    }}</gl-alert>
    <dashboards-list v-else-if="hasDashboards" :dashboards="enrichedDashboards" />
    <empty-state v-else />
  </gl-tab>
</template>
