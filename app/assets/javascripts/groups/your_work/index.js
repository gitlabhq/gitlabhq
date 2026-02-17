import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { resolvers } from '~/vue_shared/components/groups_list/resolvers';
import routes from './routes';
import YourWorkGroupsApp from './components/app.vue';

Vue.use(VueRouter);

export const createRouter = (basePath) => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: basePath,
  });

  return router;
};

export const initYourWorkGroups = () => {
  const el = document.getElementById('js-your-work-groups-app');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { initialSort, endpoint, basePath } = convertObjectPropsToCamelCase(JSON.parse(appData));

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers(endpoint)),
  });

  return new Vue({
    el,
    router: createRouter(basePath),
    apolloProvider,
    name: 'YourWorkGroupsRoot',
    render(createElement) {
      return createElement(YourWorkGroupsApp, { props: { initialSort } });
    },
  });
};
