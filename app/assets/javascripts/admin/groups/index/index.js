import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import routes from './routes';
import AdminGroupsApp from './components/app.vue';

Vue.use(VueRouter);

export const createRouter = () => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: gon.relative_url_root || '/',
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
    router: createRouter(),
    apolloProvider,
    name: 'AdminGroupsRoot',
    render(createElement) {
      return createElement(AdminGroupsApp);
    },
  });
};
