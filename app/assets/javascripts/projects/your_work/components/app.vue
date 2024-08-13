<script>
import { GlTabs, GlTab, GlBadge, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  PROJECT_DASHBOARD_TABS,
  CONTRIBUTED_TAB,
  CUSTOM_DASHBOARD_ROUTE_NAMES,
} from 'ee_else_ce/projects/your_work/constants';

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
      activeTabIndex: this.initActiveTabIndex(),
    };
  },
  computed: {
    formattedTabs() {
      return PROJECT_DASHBOARD_TABS.map((tab) => ({ ...tab, count: 0 }));
    },
  },
  methods: {
    initActiveTabIndex() {
      return CUSTOM_DASHBOARD_ROUTE_NAMES.includes(this.$route.name)
        ? 0
        : PROJECT_DASHBOARD_TABS.findIndex((tab) => tab.value === this.$route.name);
    },
    onTabUpdate(index) {
      // This return will prevent us overwriting the root `/` and `/dashboard/projects` paths
      // when we don't need to.
      if (index === this.activeTabIndex) return;

      this.activeTabIndex = index;

      const tab = PROJECT_DASHBOARD_TABS[index] || CONTRIBUTED_TAB;
      this.$router.push({ name: tab.value });
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
