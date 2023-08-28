import Vue from 'vue';
import VueRouter from 'vue-router';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { ORGANIZATION_ROOT_ROUTE_NAME } from '../constants';
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
  const { organization, groupsAndProjectsOrganizationPath } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
  );

  Vue.use(VueRouter);
  const router = createRouter();

  return new Vue({
    el,
    name: 'OrganizationShowRoot',
    router,
    render(createElement) {
      return createElement(App, { props: { organization, groupsAndProjectsOrganizationPath } });
    },
  });
};
