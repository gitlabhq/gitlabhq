<script>
import { GlTabs, GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash-es';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import DashboardListTab from '../components/dashboard_list_tab.vue';
import NewDashboardButton from '../components/new_dashboard_button.vue';

const DEFAULT_ACTIVE_TAB_INDEX = 0; // Defaults to the 'All' tab
const MIN_SEARCH_TEXT_LENGTH = 3;

export default {
  name: 'ExploreAnalyticsDashboardsList',
  components: {
    DashboardListTab,
    GlTabs,
    GlSearchBoxByType,
    PageHeading,
    NewDashboardButton,
  },
  data() {
    return { searchText: '', activeTabIndex: DEFAULT_ACTIVE_TAB_INDEX };
  },
  methods: {
    handleSearchText: debounce(function debouncedSearch(searchText) {
      const search = searchText.trim();
      this.searchText = search.length >= MIN_SEARCH_TEXT_LENGTH ? search : '';
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
  },
};
</script>
<template>
  <div>
    <page-heading :heading="__('Analytics dashboards')">
      <template #actions>
        <new-dashboard-button />
      </template>
      <template #description>
        {{
          s__('AnalyticsDashboards|Keep your teams aligned around the metrics that matter most.')
        }}
      </template>
    </page-heading>
    <gl-tabs v-model="activeTabIndex" content-class="gl-p-0">
      <div class="gl-bg-subtle gl-p-5">
        <gl-search-box-by-type @input="handleSearchText" />
      </div>

      <dashboard-list-tab
        :title="s__('AnalyticsDashboards|All')"
        :sr-text="s__('AnalyticsDashboards|All available dashboards')"
        :search="searchText"
      />
      <dashboard-list-tab
        :title="s__('AnalyticsDashboards|Created by me')"
        :sr-text="s__('AnalyticsDashboards|Dashboards created by me')"
        scope="USER"
        :search="searchText"
      />
      <dashboard-list-tab
        :title="s__('AnalyticsDashboards|Created by GitLab')"
        :sr-text="s__('AnalyticsDashboards|Dashboards created by GitLab')"
        scope="GITLAB"
        :search="searchText"
      />
    </gl-tabs>
  </div>
</template>
