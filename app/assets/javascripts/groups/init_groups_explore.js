import Vue from 'vue';
import VueRouter from 'vue-router';
import GroupItem from 'jh_else_ce/groups/components/group_item.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import GroupFolder from './components/group_folder.vue';
import GroupsExploreApp from './components/groups_explore_app.vue';

export const createRouter = () => {
  const routes = [{ path: '/', name: 'root' }];

  const router = new VueRouter({
    routes,
    base: '/',
    mode: 'history',
  });

  return router;
};

export const initGroupsExplore = () => {
  const el = document.getElementById('js-groups-explore');

  if (!el) return false;

  // Register components globally to avoid circular references issue
  // See https://v2.vuejs.org/v2/guide/components-edge-cases#Circular-References-Between-Components
  Vue.component('GroupFolder', GroupFolder);
  Vue.component('GroupItem', GroupItem);

  const {
    dataset: { appData },
  } = el;
  const { groupsEmptyStateIllustration, emptySearchIllustration, endpoint, initialSort } =
    convertObjectPropsToCamelCase(JSON.parse(appData));

  Vue.use(VueRouter);
  const router = createRouter();

  return new Vue({
    el,
    name: 'GroupsExploreRoot',
    provide: { groupsEmptyStateIllustration, emptySearchIllustration, endpoint, initialSort },
    router,
    render(createElement) {
      return createElement(GroupsExploreApp);
    },
  });
};
