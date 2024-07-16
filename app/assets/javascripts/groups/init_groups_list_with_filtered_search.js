import Vue from 'vue';
import VueRouter from 'vue-router';
import GroupItem from 'jh_else_ce/groups/components/group_item.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import GroupFolder from './components/group_folder.vue';
import GroupsListWithFilteredSearchApp from './components/groups_list_with_filtered_search_app.vue';

export const createRouter = () => {
  const routes = [{ path: '/', name: 'root' }];

  const router = new VueRouter({
    routes,
    base: '/',
    mode: 'history',
  });

  return router;
};

export const initGroupsListWithFilteredSearch = ({ filteredSearchNamespace, EmptyState }) => {
  const el = document.getElementById('js-groups-list-with-filtered-search');

  if (!el) return false;

  // Register components globally to avoid circular references issue
  // See https://v2.vuejs.org/v2/guide/components-edge-cases#Circular-References-Between-Components
  Vue.component('GroupFolder', GroupFolder);
  Vue.component('GroupItem', GroupItem);

  const {
    dataset: { appData },
  } = el;
  const { endpoint, initialSort } = convertObjectPropsToCamelCase(JSON.parse(appData));

  Vue.use(VueRouter);
  const router = createRouter();

  return new Vue({
    el,
    name: 'GroupsExploreRoot',
    router,
    render(createElement) {
      return createElement(GroupsListWithFilteredSearchApp, {
        props: {
          filteredSearchNamespace,
          endpoint,
          initialSort,
        },
        scopedSlots: {
          'empty-state': () => createElement(EmptyState),
        },
      });
    },
  });
};
