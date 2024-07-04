import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import { ORGANIZATION_ROOT_ROUTE_NAME } from '~/organizations/shared/constants';
import App from './components/app.vue';

export const createRouter = () => {
  const routes = [{ path: '/', name: ORGANIZATION_ROOT_ROUTE_NAME }];

  const router = new VueRouter({
    routes,
    base: '/',
    mode: 'history',
  });

  return router;
};

export const initOrganizationsShow = () => {
  const el = document.getElementById('js-organizations-show');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const {
    organizationGid,
    organization,
    groupsAndProjectsOrganizationPath,
    usersOrganizationPath,
    newGroupPath,
    groupsPath,
    newProjectPath,
    associationCounts,
    canCreateProject,
    canCreateGroup,
    hasGroups,
  } = convertObjectPropsToCamelCase(JSON.parse(appData));

  Vue.use(VueRouter);
  const router = createRouter();
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'OrganizationShowRoot',
    apolloProvider,
    router,
    provide: {
      organizationGid,
      newGroupPath,
      groupsPath,
      newProjectPath,
      canCreateProject,
      canCreateGroup,
      hasGroups,
    },
    render(createElement) {
      return createElement(App, {
        props: {
          organization,
          groupsAndProjectsOrganizationPath,
          usersOrganizationPath,
          associationCounts,
        },
      });
    },
  });
};
