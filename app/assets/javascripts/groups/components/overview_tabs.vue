<script>
import { GlTabs, GlTab } from '@gitlab/ui';
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
          title: this.$options.i18n.subgroupsAndProjects,
          key: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
          renderEmptyState: true,
          lazy: false,
          service: new GroupsService(this.endpoints[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]),
          store: new GroupsStore({ showSchemaMarkup: true }),
        },
        {
          title: this.$options.i18n.sharedProjects,
          key: ACTIVE_TAB_SHARED,
          renderEmptyState: false,
          lazy: true,
          service: new GroupsService(this.endpoints[ACTIVE_TAB_SHARED]),
          store: new GroupsStore(),
        },
        {
          title: this.$options.i18n.archivedProjects,
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
  methods: {
    handleTabInput(tabIndex) {
      this.activeTabIndex = tabIndex;

      const tab = this.tabs[tabIndex];
      tab.lazy = false;
    },
  },
  i18n: {
    subgroupsAndProjects: __('Subgroups and projects'),
    sharedProjects: __('Shared projects'),
    archivedProjects: __('Archived projects'),
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
