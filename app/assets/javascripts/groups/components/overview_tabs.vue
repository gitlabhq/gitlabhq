<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { isString } from 'lodash';
import { __ } from '~/locale';
import GroupsStore from '../store/groups_store';
import GroupsService from '../service/groups_service';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_ARCHIVED,
} from '../constants';
import GroupsApp from './app.vue';

export default {
  components: { GlTabs, GlTab, GroupsApp },
  inject: ['endpoints'],
  data() {
    return {
      tabs: [
        {
          title: this.$options.i18n[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS],
          key: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
          renderEmptyState: true,
          lazy: false,
          service: new GroupsService(this.endpoints[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]),
          store: new GroupsStore({ showSchemaMarkup: true }),
        },
        {
          title: this.$options.i18n[ACTIVE_TAB_SHARED],
          key: ACTIVE_TAB_SHARED,
          renderEmptyState: false,
          lazy: true,
          service: new GroupsService(this.endpoints[ACTIVE_TAB_SHARED]),
          store: new GroupsStore(),
        },
        {
          title: this.$options.i18n[ACTIVE_TAB_ARCHIVED],
          key: ACTIVE_TAB_ARCHIVED,
          renderEmptyState: false,
          lazy: true,
          service: new GroupsService(this.endpoints[ACTIVE_TAB_ARCHIVED]),
          store: new GroupsStore(),
        },
      ],
      activeTabIndex: 0,
    };
  },
  mounted() {
    const activeTabIndex = this.tabs.findIndex((tab) => tab.key === this.$route.name);

    if (activeTabIndex === -1) {
      return;
    }

    this.activeTabIndex = activeTabIndex;
  },
  methods: {
    handleTabInput(tabIndex) {
      if (tabIndex === this.activeTabIndex) {
        return;
      }

      this.activeTabIndex = tabIndex;

      const tab = this.tabs[tabIndex];
      tab.lazy = false;

      // Vue router will convert `/` to `%2F` if you pass a string as a param
      // If you pass an array as a param it will concatenate them with a `/`
      // This makes sure we are always passing an array for the group param
      const groupParam = isString(this.$route.params.group)
        ? this.$route.params.group.split('/')
        : this.$route.params.group;

      this.$router.push({ name: tab.key, params: { group: groupParam } });
    },
  },
  i18n: {
    [ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]: __('Subgroups and projects'),
    [ACTIVE_TAB_SHARED]: __('Shared projects'),
    [ACTIVE_TAB_ARCHIVED]: __('Archived projects'),
  },
};
</script>

<template>
  <gl-tabs content-class="gl-pt-0" :value="activeTabIndex" @input="handleTabInput">
    <gl-tab
      v-for="{ key, title, renderEmptyState, lazy, service, store } in tabs"
      :key="key"
      :title="title"
      :lazy="lazy"
    >
      <groups-app
        :action="key"
        :service="service"
        :store="store"
        :hide-projects="false"
        :render-empty-state="renderEmptyState"
      />
    </gl-tab>
  </gl-tabs>
</template>
