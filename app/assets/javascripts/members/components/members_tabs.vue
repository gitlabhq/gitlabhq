<script>
import { GlTabs, GlTab, GlBadge, GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { queryToObject } from '~/lib/utils/url_utility';
import { MEMBERS_TAB_TYPES, ACTIVE_TAB_QUERY_PARAM_NAME } from 'ee_else_ce/members/constants';
import { TABS } from 'ee_else_ce/members/tabs_metadata';
import MembersApp from './app.vue';

const countComputed = (state, namespace) => state[namespace]?.pagination?.totalItems || 0;

export default {
  name: 'MembersTabs',
  ACTIVE_TAB_QUERY_PARAM_NAME,
  TABS,
  components: { MembersApp, GlTabs, GlTab, GlBadge, GlButton },
  inject: ['canManageMembers', 'canManageAccessRequests', 'canExportMembers', 'exportCsvPath'],
  data() {
    return {
      selectedTabIndex: 0,
    };
  },
  computed: {
    ...mapState(
      Object.values(MEMBERS_TAB_TYPES).reduce((getters, memberType) => {
        return {
          ...getters,
          // eslint-disable-next-line @gitlab/require-i18n-strings
          [`${memberType}Count`](state) {
            return countComputed(state, memberType);
          },
        };
      }, {}),
    ),
    urlParams() {
      return Object.keys(queryToObject(window.location.search, { gatherArrays: true }));
    },
    activeTabIndexCalculatedFromUrlParams() {
      return this.$options.TABS.findIndex(({ namespace }) => {
        return this.getTabUrlParams(namespace).some((urlParam) =>
          this.urlParams.includes(urlParam),
        );
      });
    },
    shouldShowExportButton() {
      return this.canExportMembers && !this.tabs[this.selectedTabIndex].hideExportButton;
    },
    tabs() {
      return this.$options.TABS.filter(this.showTab);
    },
  },
  methods: {
    getTabUrlParams(namespace) {
      const state = this.$store.state[namespace];
      const urlParams = [];

      if (state?.filteredSearchBar?.searchParam) {
        urlParams.push(state.filteredSearchBar.searchParam);
      }

      if (state?.filteredSearchBar?.tokens) {
        urlParams.push(...state.filteredSearchBar.tokens);
      }

      return urlParams;
    },
    getTabCount({ namespace }) {
      return this[`${namespace}Count`];
    },
    showTab(tab, index) {
      if (tab.namespace === MEMBERS_TAB_TYPES.user) {
        return true;
      }

      const { requiredPermissions = [] } = tab;
      const tabCanBeShown =
        this.getTabCount(tab) > 0 || this.activeTabIndexCalculatedFromUrlParams === index;

      return (
        tabCanBeShown && requiredPermissions.every((requiredPermission) => this[requiredPermission])
      );
    },
  },
};
</script>

<template>
  <gl-tabs
    v-model="selectedTabIndex"
    content-class="gl-py-0"
    sync-active-tab-with-query-params
    :query-param-name="$options.ACTIVE_TAB_QUERY_PARAM_NAME"
  >
    <gl-tab
      v-for="tab in tabs"
      :key="tab.namespace"
      :title-link-attributes="tab.attrs"
      :query-param-value="tab.queryParamValue"
      :lazy="tab.lazy"
    >
      <template #title>
        <span>{{ tab.title }}</span>
        <gl-badge class="gl-tab-counter-badge">{{ getTabCount(tab) }}</gl-badge>
      </template>
      <component
        :is="tab.component"
        v-if="tab.component"
        :namespace="tab.namespace"
        :tab-query-param-value="tab.queryParamValue"
      />
      <members-app v-else :namespace="tab.namespace" :tab-query-param-value="tab.queryParamValue" />
    </gl-tab>
    <template #tabs-end>
      <gl-button
        v-if="shouldShowExportButton"
        data-event-tracking="click_export_group_members_as_csv"
        class="gl-ml-auto gl-self-center"
        :href="exportCsvPath"
      >
        {{ __('Export as CSV') }}
      </gl-button>
    </template>
  </gl-tabs>
</template>
