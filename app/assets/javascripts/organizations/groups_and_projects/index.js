import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { ORGANIZATION_ROOT_ROUTE_NAME } from '~/organizations/shared/constants';
import { userPreferenceSortName, userPreferenceSortDirection } from './utils';
import App from './components/app.vue';

export const createRouter = () => {
  const routes = [{ path: '/', name: ORGANIZATION_ROOT_ROUTE_NAME, component: App }];

  const router = new VueRouter({
    routes,
    base: '/',
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
    groupsPath,
    newProjectPath,
    canCreateGroup,
    canCreateProject,
    hasGroups,
    userPreferenceSort,
    userPreferenceDisplay,
  } = convertObjectPropsToCamelCase(JSON.parse(appData));

  Vue.use(VueRouter);
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });
  const router = createRouter();

  return new Vue({
    el,
    name: 'OrganizationsGroupsAndProjects',
    apolloProvider,
    router,
    provide: {
      organizationGid,
      newGroupPath,
      groupsPath,
      newProjectPath,
      canCreateGroup,
      canCreateProject,
      hasGroups,
      userPreferenceSortName: userPreferenceSortName(userPreferenceSort),
      userPreferenceSortDirection: userPreferenceSortDirection(userPreferenceSort),
      userPreferenceDisplay,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
