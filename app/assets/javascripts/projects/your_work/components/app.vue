<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import { TIMESTAMP_TYPE_UPDATED_AT } from '~/vue_shared/components/resource_lists/constants';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { createAlert } from '~/alert';
import {
  CONTRIBUTED_TAB,
  CUSTOM_DASHBOARD_ROUTE_NAMES,
  PROJECT_DASHBOARD_TABS,
} from '../constants';
import projectCountsQuery from '../graphql/queries/project_counts.query.graphql';
import TabView from './tab_view.vue';

export default {
  name: 'YourWorkProjectsApp',
  TIMESTAMP_TYPE_UPDATED_AT,
  PROJECT_DASHBOARD_TABS,
  i18n: {
    heading: __('Projects'),
    projectCountError: __('An error occurred loading the project counts.'),
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
      counts: PROJECT_DASHBOARD_TABS.reduce((accumulator, tab) => {
        return {
          ...accumulator,
          [tab.value]: undefined,
        };
      }, {}),
    };
  },
  apollo: {
    counts() {
      return {
        query: projectCountsQuery,
        update(response) {
          const {
            currentUser: { contributed, starred },
            personal,
            member,
            inactive,
          } = response;

          return Object.entries({ contributed, starred, personal, member, inactive }).reduce(
            (accumulator, [tab, item]) => {
              return {
                ...accumulator,
                [tab]: item.count,
              };
            },
            {},
          );
        },
        error(error) {
          createAlert({ message: this.$options.i18n.projectCountError, error, captureError: true });
        },
      };
    },
  },
  methods: {
    numberToMetricPrefix,
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
    tabCount(tab) {
      return this.counts[tab.value];
    },
    shouldShowCountBadge(tab) {
      return this.tabCount(tab) !== undefined;
    },
  },
};
</script>

<template>
  <div>
    <h1 class="page-title gl-mt-5 gl-text-size-h-display">{{ $options.i18n.heading }}</h1>

    <gl-tabs :value="activeTabIndex" @input="onTabUpdate">
      <gl-tab v-for="tab in $options.PROJECT_DASHBOARD_TABS" :key="tab.text" lazy>
        <template #title>
          <div class="gl-flex gl-items-center gl-gap-2" data-testid="projects-dashboard-tab-title">
            <span>{{ tab.text }}</span>
            <gl-badge v-if="shouldShowCountBadge(tab)" size="sm" class="gl-tab-counter-badge">{{
              numberToMetricPrefix(tabCount(tab))
            }}</gl-badge>
          </div>
        </template>

        <tab-view v-if="tab.query" :tab="tab" />
        <template v-else>{{ tab.text }}</template>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
