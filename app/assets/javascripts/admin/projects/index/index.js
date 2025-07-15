import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import AdminProjectsApp from '~/admin/projects/index/components/app.vue';
import routes from './routes';

Vue.use(VueRouter);

export const createRouter = () => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: gon.relative_url_root || '/',
  });

  return router;
};

export const initAdminProjects = () => {
  const el = document.getElementById('js-admin-projects-app');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { programmingLanguages } = convertObjectPropsToCamelCase(JSON.parse(appData));

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    router: createRouter(),
    apolloProvider,
    name: 'AdminProjectsRoot',
    render(createElement) {
      return createElement(AdminProjectsApp, {
        props: { programmingLanguages },
      });
    },
  });
};
