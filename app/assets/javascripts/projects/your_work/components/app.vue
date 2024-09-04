<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import { TIMESTAMP_TYPE_UPDATED_AT } from '~/vue_shared/components/resource_lists/constants';
import {
  CONTRIBUTED_TAB,
  CUSTOM_DASHBOARD_ROUTE_NAMES,
  PROJECT_DASHBOARD_TABS,
} from 'ee_else_ce/projects/your_work/constants';
import TabView from './tab_view.vue';

export default {
  name: 'YourWorkProjectsApp',
  TIMESTAMP_TYPE_UPDATED_AT,
  i18n: {
    heading: __('Projects'),
  },
  components: {
    GlTabs,
    GlTab,
    GlBadge,
    TabView,
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
    <h1 class="page-title gl-mt-5 gl-text-size-h-display">{{ $options.i18n.heading }}</h1>

    <gl-tabs :value="activeTabIndex" @input="onTabUpdate">
      <gl-tab v-for="tab in formattedTabs" :key="tab.text" lazy>
        <template #title>
          <span data-testid="projects-dashboard-tab-title">
            <span>{{ tab.text }}</span>
            <gl-badge size="sm" class="gl-tab-counter-badge">{{ tab.count }}</gl-badge>
          </span>
        </template>

        <tab-view v-if="tab.query" :tab="tab" />
        <template v-else>{{ tab.text }}</template>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
