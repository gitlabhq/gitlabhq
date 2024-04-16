<script>
import { GlTabs, GlTab, GlBadge, GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { queryToObject } from '~/lib/utils/url_utility';
import { MEMBER_TYPES, TABS, ACTIVE_TAB_QUERY_PARAM_NAME } from 'ee_else_ce/members/constants';
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
      Object.values(MEMBER_TYPES).reduce((getters, memberType) => {
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
      if (tab.namespace === MEMBER_TYPES.user) {
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
    <template v-for="(tab, index) in $options.TABS">
      <gl-tab
        v-if="showTab(tab, index)"
        :key="tab.namespace"
        :title-link-attributes="tab.attrs"
        :query-param-value="tab.queryParamValue"
      >
        <template #title>
          <span>{{ tab.title }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ getTabCount(tab) }}</gl-badge>
        </template>
        <component :is="tab.component" v-if="tab.component" :namespace="tab.namespace" />
        <members-app
          v-else
          :namespace="tab.namespace"
          :tab-query-param-value="tab.queryParamValue"
        />
      </gl-tab>
    </template>
    <template #tabs-end>
      <gl-button
        v-if="canExportMembers"
        class="gl-align-self-center gl-ml-auto"
        icon="export"
        :href="exportCsvPath"
      >
        {{ __('Export as CSV') }}
      </gl-button>
    </template>
  </gl-tabs>
</template>
