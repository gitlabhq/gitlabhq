import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { ORGANIZATION_ROOT_ROUTE_NAME } from '~/organizations/shared/constants';
import { userPreferenceSortName, userPreferenceSortDirection } from './utils';
import App from './components/app.vue';

Vue.use(VueApollo);

export const createRouter = (basePath) => {
  const routes = [{ path: '/', name: ORGANIZATION_ROOT_ROUTE_NAME, component: App }];

  const router = new VueRouter({
    routes,
    base: basePath,
    mode: 'history',
  });

  return router;
};

export const initOrganizationsGroupsAndProjects = () => {
  const el = document.getElementById('js-organizations-groups-and-projects');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const {
    organizationGid,
    newGroupPath,
    newProjectPath,
    canCreateGroup,
    canCreateProject,
    hasGroups,
    userPreferenceSort,
    userPreferenceDisplay,
    basePath,
  } = convertObjectPropsToCamelCase(JSON.parse(appData));

  Vue.use(VueRouter);
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });
  const router = createRouter(basePath);

  return initVueApp({
    el,
    name: 'OrganizationsGroupsAndProjects',
    apolloProvider,
    router,
    provide: {
      organizationGid,
      newGroupPath,
      newProjectPath,
      canCreateGroup,
      canCreateProject,
      hasGroups,
      userPreferenceSortName: userPreferenceSortName(userPreferenceSort),
      userPreferenceSortDirection: userPreferenceSortDirection(userPreferenceSort),
      userPreferenceDisplay,
    },
    component: App,
  });
};
