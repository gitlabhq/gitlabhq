import Vue from 'vue';
import VueRouter from 'vue-router';
import { GlToast } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import GroupItem from 'jh_else_ce/groups/components/group_item.vue';
import GroupFolder from './components/group_folder.vue';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_INACTIVE,
} from './constants';
import OverviewTabs from './components/overview_tabs.vue';

export const createRouter = () => {
  const routes = [
    { name: ACTIVE_TAB_SHARED, path: '/groups/:group*/-/shared' },
    { name: ACTIVE_TAB_INACTIVE, path: '/groups/:group*/-/inactive' },
    { name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS, path: '/:group*' },
  ];

  const router = new VueRouter({
    routes,
    mode: 'history',
    base: gon.relative_url_root || '/',
  });

  return router;
};

export const initGroupOverviewTabs = () => {
  const el = document.getElementById('js-group-overview-tabs');

  if (!el) return false;

  Vue.component('GroupFolder', GroupFolder);
  Vue.component('GroupItem', GroupItem);
  Vue.use(GlToast);
  Vue.use(VueRouter);

  const router = createRouter();

  const {
    groupId,
    newSubgroupPath,
    newProjectPath,
    emptyProjectsIllustration,
    emptySubgroupIllustration,
    canCreateSubgroups,
    canCreateProjects,
    currentGroupVisibility,
    subgroupsAndProjectsEndpoint,
    sharedProjectsEndpoint,
    inactiveProjectsEndpoint,
    initialSort,
  } = el.dataset;

  return new Vue({
    el,
    router,
    provide: {
      groupId,
      newSubgroupPath,
      newProjectPath,
      emptyProjectsIllustration,
      emptySubgroupIllustration,
      canCreateSubgroups: parseBoolean(canCreateSubgroups),
      canCreateProjects: parseBoolean(canCreateProjects),
      currentGroupVisibility,
      endpoints: {
        [ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]: subgroupsAndProjectsEndpoint,
        [ACTIVE_TAB_SHARED]: sharedProjectsEndpoint,
        [ACTIVE_TAB_INACTIVE]: inactiveProjectsEndpoint,
      },
      initialSort,
    },
    render(createElement) {
      return createElement(OverviewTabs);
    },
  });
};
