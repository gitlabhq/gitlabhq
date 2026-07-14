<script>
import { GlBadge, GlButton, GlTab, GlTabs } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { getParameterByName, queryToObject, setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import {
  ACTIVE_TAB_QUERY_PARAM_NAME,
  DIRECT_MEMBERS_PAGE_QUERY_PARAM_NAME,
  MEMBERS_TAB_TYPES,
  TAB_QUERY_PARAM_VALUES,
} from 'ee_else_ce/members/constants';
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
  mounted() {
    this.ensureDirectMembersPageParam();
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
    tabPath(value) {
      const params = { tab: value };

      // The Direct members tab must request page 1 explicitly so the backend
      // loads direct members via the dedicated finder rather than deriving them
      // from the combined members page (which can omit direct members that fall
      // on a later page of the combined list).
      if (value === TAB_QUERY_PARAM_VALUES.directMembers) {
        params[DIRECT_MEMBERS_PAGE_QUERY_PARAM_NAME] = 1;
      }

      return setUrlParams(params, { clearParams: true });
    },
    titleLinkAttrs({ attrs, queryParamValue: value }) {
      return { ...attrs, href: this.tabPath(value) };
    },
    ensureDirectMembersPageParam() {
      // When landing directly on the Direct members tab (e.g. via a bookmark or
      // shared link) without the page param, the server-rendered seed comes from
      // the wrong code path. Reload with the page param so the dedicated finder
      // provides the correct, complete list.
      const isDirectMembersTab =
        getParameterByName(ACTIVE_TAB_QUERY_PARAM_NAME) === TAB_QUERY_PARAM_VALUES.directMembers;
      const hasPageParam = getParameterByName(DIRECT_MEMBERS_PAGE_QUERY_PARAM_NAME) !== null;

      if (isDirectMembersTab && !hasPageParam) {
        visitUrl(setUrlParams({ [DIRECT_MEMBERS_PAGE_QUERY_PARAM_NAME]: 1 }));
      }
    },
  },
};
</script>

<template>
  <gl-tabs
    v-model="selectedTabIndex"
    content-class="gl-py-0 gl-isolation-auto"
    sync-active-tab-with-query-params
    :query-param-name="$options.ACTIVE_TAB_QUERY_PARAM_NAME"
  >
    <gl-tab
      v-for="tab in tabs"
      :key="tab.namespace"
      :title-link-attributes="titleLinkAttrs(tab)"
      title-link-class="gl-p-0"
      :query-param-value="tab.queryParamValue"
      :lazy="tab.lazy"
    >
      <template #title>
        <span :data-testid="`${tab.namespace}-tab-title`" class="gl-px-4 gl-py-5" @click.stop>
          {{ tab.title }} <gl-badge class="gl-tab-counter-badge">{{ getTabCount(tab) }}</gl-badge>
        </span>
      </template>
      <component
        :is="tab.component"
        v-if="tab.component"
        :namespace="tab.namespace"
        :tab-query-param-value="tab.queryParamValue"
      />
      <members-app v-else :namespace="tab.namespace" :tab-query-param-value="tab.queryParamValue" />
    </gl-tab>
    <template #toolbar-end>
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
