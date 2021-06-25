<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { mapState } from 'vuex';
// eslint-disable-next-line import/no-deprecated
import { urlParamsToObject } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { MEMBER_TYPES, TAB_QUERY_PARAM_VALUES, ACTIVE_TAB_QUERY_PARAM_NAME } from '../constants';
import MembersApp from './app.vue';

const countComputed = (state, namespace) => state[namespace]?.pagination?.totalItems || 0;

export default {
  name: 'MembersTabs',
  ACTIVE_TAB_QUERY_PARAM_NAME,
  TABS: [
    {
      namespace: MEMBER_TYPES.user,
      title: __('Members'),
    },
    {
      namespace: MEMBER_TYPES.group,
      title: __('Groups'),
      attrs: { 'data-qa-selector': 'groups_list_tab' },
      queryParamValue: TAB_QUERY_PARAM_VALUES.group,
    },
    {
      namespace: MEMBER_TYPES.invite,
      title: __('Invited'),
      canManageMembersPermissionsRequired: true,
      queryParamValue: TAB_QUERY_PARAM_VALUES.invite,
    },
    {
      namespace: MEMBER_TYPES.accessRequest,
      title: __('Access requests'),
      canManageMembersPermissionsRequired: true,
      queryParamValue: TAB_QUERY_PARAM_VALUES.accessRequest,
    },
  ],
  components: { MembersApp, GlTabs, GlTab, GlBadge },
  inject: ['canManageMembers'],
  data() {
    return {
      selectedTabIndex: 0,
    };
  },
  computed: {
    ...mapState({
      userCount(state) {
        return countComputed(state, MEMBER_TYPES.user);
      },
      groupCount(state) {
        return countComputed(state, MEMBER_TYPES.group);
      },
      inviteCount(state) {
        return countComputed(state, MEMBER_TYPES.invite);
      },
      accessRequestCount(state) {
        return countComputed(state, MEMBER_TYPES.accessRequest);
      },
    }),
    urlParams() {
      // eslint-disable-next-line import/no-deprecated
      return Object.keys(urlParamsToObject(window.location.search));
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

      return urlParams;
    },
    getTabCount({ namespace }) {
      return this[`${namespace}Count`];
    },
    showTab(tab, index) {
      if (tab.namespace === MEMBER_TYPES.user) {
        return true;
      }

      const { canManageMembersPermissionsRequired = false } = tab;
      const tabCanBeShown =
        this.getTabCount(tab) > 0 || this.activeTabIndexCalculatedFromUrlParams === index;

      if (canManageMembersPermissionsRequired) {
        return this.canManageMembers && tabCanBeShown;
      }

      return tabCanBeShown;
    },
  },
};
</script>

<template>
  <gl-tabs
    v-model="selectedTabIndex"
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
        <members-app :namespace="tab.namespace" :tab-query-param-value="tab.queryParamValue" />
      </gl-tab>
    </template>
  </gl-tabs>
</template>
