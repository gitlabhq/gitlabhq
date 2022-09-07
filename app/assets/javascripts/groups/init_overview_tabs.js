import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import GroupFolder from './components/group_folder.vue';
import GroupItem from './components/group_item.vue';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_ARCHIVED,
} from './constants';
import OverviewTabs from './components/overview_tabs.vue';

export const initGroupOverviewTabs = () => {
  const el = document.getElementById('js-group-overview-tabs');

  if (!el) return false;

  Vue.component('GroupFolder', GroupFolder);
  Vue.component('GroupItem', GroupItem);
  Vue.use(GlToast);

  const {
    newSubgroupPath,
    newProjectPath,
    newSubgroupIllustration,
    newProjectIllustration,
    emptySubgroupIllustration,
    canCreateSubgroups,
    canCreateProjects,
    currentGroupVisibility,
    subgroupsAndProjectsEndpoint,
    sharedProjectsEndpoint,
    archivedProjectsEndpoint,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      newSubgroupPath,
      newProjectPath,
      newSubgroupIllustration,
      newProjectIllustration,
      emptySubgroupIllustration,
      canCreateSubgroups: parseBoolean(canCreateSubgroups),
      canCreateProjects: parseBoolean(canCreateProjects),
      currentGroupVisibility,
      endpoints: {
        [ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]: subgroupsAndProjectsEndpoint,
        [ACTIVE_TAB_SHARED]: sharedProjectsEndpoint,
        [ACTIVE_TAB_ARCHIVED]: archivedProjectsEndpoint,
      },
    },
    render(createElement) {
      return createElement(OverviewTabs);
    },
  });
};
