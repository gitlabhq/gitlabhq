<script>
import { GlTabs, GlTab, GlBadge, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { joinPaths, updateHistory, pathSegments } from '~/lib/utils/url_utility';
import { PROJECT_DASHBOARD_TABS, CONTRIBUTED_TAB } from 'ee_else_ce/projects/your_work/constants';

export default {
  name: 'YourWorkProjectsApp',
  i18n: {
    heading: __('Projects'),
    activeTab: __('Active tab: %{tab}'),
  },
  components: {
    GlTabs,
    GlTab,
    GlBadge,
    GlSprintf,
  },
  data() {
    return {
      activeTabIndex: 0,
    };
  },
  computed: {
    formattedTabs() {
      return PROJECT_DASHBOARD_TABS.map((tab) => ({ ...tab, count: 0 }));
    },
  },
  created() {
    this.getTabFromUrl();
  },
  methods: {
    getTabFromUrl() {
      const tab = pathSegments(window.location)?.pop();
      const tabIndex = PROJECT_DASHBOARD_TABS.findIndex(({ value }) => value === tab);

      this.activeTabIndex = tabIndex > 0 ? tabIndex : 0;
    },
    setTabInUrl() {
      const tab = PROJECT_DASHBOARD_TABS[this.activeTabIndex] || CONTRIBUTED_TAB;
      const url = joinPaths(gon.relative_url_root || '/', `/dashboard/projects/${tab.value}`);

      updateHistory({ url, replace: true });
    },
    onTabUpdate(index) {
      // This return will prevent us overwriting the root `/` and `/dashboard/projects` paths
      // when we don't need to.
      if (index === this.activeTabIndex) return;

      this.activeTabIndex = index;
      this.setTabInUrl();
    },
  },
};
</script>

<template>
  <div>
    <h1 class="page-title gl-font-size-h-display gl-mt-5">{{ $options.i18n.heading }}</h1>

    <gl-tabs :value="activeTabIndex" @input="onTabUpdate">
      <gl-tab v-for="tab in formattedTabs" :key="tab.text">
        <template #title>
          <span data-testid="projects-dashboard-tab-title">
            <span>{{ tab.text }}</span>
            <gl-badge size="sm" class="gl-tab-counter-badge">{{ tab.count }}</gl-badge>
          </span>
        </template>

        <gl-sprintf :message="$options.i18n.activeTab">
          <template #tab>
            {{ tab.text }}
          </template>
        </gl-sprintf>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
