import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import routes from './routes';
import YourWorkGroupsApp from './components/app.vue';
import { resolvers } from './graphql/resolvers';

Vue.use(VueRouter);

export const createRouter = () => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: gon.relative_url_root || '/',
  });

  return router;
};

export const initYourWorkGroups = () => {
  const el = document.getElementById('js-your-work-groups-app');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { initialSort, endpoint } = convertObjectPropsToCamelCase(JSON.parse(appData));

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers(endpoint)),
  });

  // We need to globally render components to avoid circular references
  // https://v2.vuejs.org/v2/guide/components-edge-cases.html#Circular-References-Between-Components
  Vue.component('NestedGroupsProjectsList', NestedGroupsProjectsList);
  Vue.component('NestedGroupsProjectsListItem', NestedGroupsProjectsListItem);

  return new Vue({
    el,
    router: createRouter(),
    apolloProvider,
    name: 'YourWorkGroupsRoot',
    render(createElement) {
      return createElement(YourWorkGroupsApp, { props: { initialSort } });
    },
  });
};
