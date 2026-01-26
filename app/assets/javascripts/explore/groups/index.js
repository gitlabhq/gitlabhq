import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import ExploreGroupsApp from '~/explore/groups/components/app.vue';
import createDefaultClient from '~/lib/graphql';
import { resolvers } from '~/vue_shared/components/groups_list/resolvers';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import routes from '~/explore/groups/routes';

Vue.use(VueRouter);

export const createRouter = (basePath) => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: basePath,
  });

  return router;
};

export const initExploreGroups = () => {
  const el = document.getElementById('js-explore-groups');

  if (!el) return null;

  const { initialSort, endpoint, basePath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers(endpoint)),
  });

  // We need to globally render components to avoid circular references
  // https://v2.vuejs.org/v2/guide/components-edge-cases.html#Circular-References-Between-Components
  Vue.component('NestedGroupsProjectsList', NestedGroupsProjectsList);
  Vue.component('NestedGroupsProjectsListItem', NestedGroupsProjectsListItem);

  return new Vue({
    el,
    router: createRouter(basePath),
    apolloProvider,
    name: 'ExploreGroupsRoot',
    render(createElement) {
      return createElement(ExploreGroupsApp, { props: { initialSort } });
    },
  });
};
