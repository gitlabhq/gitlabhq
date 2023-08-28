import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';
import { ORGANIZATION_ROOT_ROUTE_NAME } from '../constants';
import resolvers from './graphql/resolvers';
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

export const initOrganizationsGroupsAndProjects = () => {
  const el = document.getElementById('js-organizations-groups-and-projects');

  if (!el) return false;

  Vue.use(VueRouter);
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers),
  });
  const router = createRouter();

  return new Vue({
    el,
    name: 'OrganizationsGroupsAndProjects',
    apolloProvider,
    router,
    render(createElement) {
      return createElement(App);
    },
  });
};
