<script>
import { GlSkeletonLoader, GlTabs, GlTab, GlSearchBoxByType } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import EmptyState from '~/vue_shared/components/dashboards_list/empty_state.vue';
import DashboardsList from '~/vue_shared/components/dashboards_list/dashboards_list.vue';
import getDashboardsQuery from '../graphql/get_dashboards.query.graphql';

const DEFAULT_ACTIVE_TAB_INDEX = 2; // Defaults to the 'All' tab
const MIN_SEARCH_TEXT_LENGTH = 3;

export default {
  name: 'AnalyticsDashboards',
  components: { DashboardsList, EmptyState, GlSkeletonLoader, GlTabs, GlTab, GlSearchBoxByType },
  props: {
    organizationId: {
      type: String,
      required: true,
    },
    currentUserId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return { searchText: '', activeTabIndex: DEFAULT_ACTIVE_TAB_INDEX, dashboards: [] };
  },
  computed: {
    isLoading() {
      return Boolean(this.$apollo.queries.dashboards?.loading);
    },

    createdByGitLab() {
      // TODO: to be implemented once we have https://gitlab.com/gitlab-org/gitlab/-/work_items/594906
      return [];
    },
    createdByMe() {
      return this.currentUserId
        ? this.dashboards.filter(
            ({ createdBy }) => getIdFromGraphQLId(createdBy?.id) === this.currentUserId,
          )
        : [];
    },
    groupedDashboards() {
      // NOTE: until we implement favouriting and sharing dashboards,
      //       we only have 3 tab filters for now: all, created by me, created by gitlab
      return [
        {
          title: s__('AnalyticsDashboards|Created by me'),
          list: this.createdByMe,
          count: this.createdByMe.length,
          srText: s__('AnalyticsDashboards|Dashboards created by me'),
        },
        {
          title: s__('AnalyticsDashboards|Created by GitLab'),
          list: this.createdByGitLab,
          count: this.createdByGitLab.length,
          srText: s__('AnalyticsDashboards|Dashboards created by GitLab'),
        },
        // NOTE: based on the latest designs the 'All' tab should appear as the last tab
        {
          title: s__('AnalyticsDashboards|All'),
          list: this.dashboards,
          count: this.dashboards.length,
          srText: s__('AnalyticsDashboards|All available dashboards'),
        },
      ];
    },
    selectedTabDashboards() {
      if (!this.groupedDashboards.length) return [];

      const str = this.searchText.toLowerCase().trim();
      const { list } = this.groupedDashboards[this.activeTabIndex];

      if (str.length <= MIN_SEARCH_TEXT_LENGTH) return list;
      return list.filter(({ name = '' }) => name.toLowerCase().includes(str));
    },
    hasDashboards() {
      return Boolean(this.selectedTabDashboards.length);
    },
  },
  methods: {
    handleSearchText(searchText) {
      this.searchText = searchText;
    },
    testId(index) {
      return index === this.activeTabIndex ? 'dashboard-list-tab-active' : 'dashboard-list-tab';
    },
  },
  apollo: {
    dashboards: {
      query: getDashboardsQuery,
      variables() {
        return {
          organizationId: this.organizationId,
        };
      },
      update({ customDashboards }) {
        return customDashboards?.nodes || [];
      },
      error(err) {
        createAlert({
          message: s__('AnalyticsDashboards|Failed to load dashboards list. Please try again.'),
          captureError: true,
          error: err,
        });
      },
    },
  },
};
</script>
<template>
  <gl-skeleton-loader v-if="isLoading" size="lg" />
  <gl-tabs v-else v-model="activeTabIndex" content-class="gl-p-0">
    <div class="gl-bg-subtle gl-p-5">
      <gl-search-box-by-type @input="handleSearchText" />
    </div>
    <gl-tab
      v-for="({ title, count, srText }, index) in groupedDashboards"
      :key="`dashboard-list-tab-${title}`"
      :title="title"
      :tab-count="count"
      :tab-count-sr-text="srText"
      :data-testid="testId(index)"
    >
      <dashboards-list v-if="hasDashboards" :dashboards="selectedTabDashboards" />
      <empty-state v-else />
    </gl-tab>
  </gl-tabs>
</template>
