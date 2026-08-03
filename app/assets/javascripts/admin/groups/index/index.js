import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { adminGroupsPath } from '~/lib/utils/path_helpers/admin';
import routes from './routes';
import AdminGroupsApp from './components/app.vue';

Vue.use(VueRouter);

export const createRouter = (basePath) => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: basePath,
  });

  return router;
};

export const initAdminGroups = () => {
  const el = document.getElementById('js-admin-groups-app');

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    router: createRouter(adminGroupsPath()),
    apolloProvider,
    name: 'AdminGroupsRoot',
    render(createElement) {
      return createElement(AdminGroupsApp);
    },
  });
};
