import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { resolvers } from './graphql/resolvers';
import routes from './routes';
import GroupsShowApp from './components/app.vue';

Vue.use(VueRouter);

export const createRouter = () => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: gon.relative_url_root || '/',
  });

  return router;
};

export const initGroupsShowApp = () => {
  const el = document.getElementById('js-groups-show-app');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const {
    initialSort,
    fullPath,
    subgroupsAndProjectsEndpoint,
    newSubgroupPath,
    newProjectPath,
    canCreateSubgroups,
    canCreateProjects,
    emptyProjectsIllustration,
  } = convertObjectPropsToCamelCase(JSON.parse(appData));

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers(subgroupsAndProjectsEndpoint)),
  });

  return new Vue({
    el,
    router: createRouter(),
    apolloProvider,
    name: 'GroupsShowRoot',
    provide: {
      newSubgroupPath,
      newProjectPath,
      canCreateSubgroups,
      canCreateProjects,
      emptyProjectsIllustration,
    },
    render(createElement) {
      return createElement(GroupsShowApp, { props: { initialSort, fullPath } });
    },
  });
};
