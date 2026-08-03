import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { adminProjectsPath } from '~/lib/utils/path_helpers/admin';
import AdminProjectsApp from '~/admin/projects/index/components/app.vue';
import routes from './routes';

Vue.use(VueRouter);

export const createRouter = (basePath) => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: basePath,
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

  return initVueApp({
    el,
    router: createRouter(adminProjectsPath()),
    apolloProvider,
    name: 'AdminProjectsRoot',
    component: AdminProjectsApp,
    props: { programmingLanguages },
  });
};
