<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { mapState } from 'vuex';
import { urlParamsToObject } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import { MEMBER_TYPES } from '../constants';
import MembersApp from './app.vue';

const countComputed = (state, namespace) => state[namespace]?.pagination?.totalItems || 0;

export default {
  name: 'MembersTabs',
  tabs: [
    {
      namespace: MEMBER_TYPES.user,
      title: __('Members'),
    },
    {
      namespace: MEMBER_TYPES.group,
      title: __('Groups'),
      attrs: { 'data-qa-selector': 'groups_list_tab' },
    },
    {
      namespace: MEMBER_TYPES.invite,
      title: __('Invited'),
      canManageMembersPermissionsRequired: true,
    },
    {
      namespace: MEMBER_TYPES.accessRequest,
      title: __('Access requests'),
      canManageMembersPermissionsRequired: true,
    },
  ],
  urlParams: [],
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
      return Object.keys(urlParamsToObject(window.location.search));
    },
    activeTabIndexCalculatedFromUrlParams() {
      return this.$options.tabs.findIndex(({ namespace }) => {
        return this.getTabUrlParams(namespace).some((urlParam) =>
          this.urlParams.includes(urlParam),
        );
      });
    },
  },
  created() {
    if (this.activeTabIndexCalculatedFromUrlParams === -1) {
      return;
    }

    this.selectedTabIndex = this.activeTabIndexCalculatedFromUrlParams;
  },
  methods: {
    getTabUrlParams(namespace) {
      const state = this.$store.state[namespace];
      const urlParams = [];

      if (state?.pagination?.paramName) {
        urlParams.push(state.pagination.paramName);
      }

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
  <gl-tabs v-model="selectedTabIndex">
    <template v-for="(tab, index) in $options.tabs">
      <gl-tab v-if="showTab(tab, index)" :key="tab.namespace" :title-link-attributes="tab.attrs">
        <template slot="title">
          <span>{{ tab.title }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ getTabCount(tab) }}</gl-badge>
        </template>
        <members-app :namespace="tab.namespace" />
      </gl-tab>
    </template>
  </gl-tabs>
</template>
