import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import routes from './routes';
import YourWorkProjectsApp from './components/app.vue';

Vue.use(VueRouter);

export const createRouter = () => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: gon.relative_url_root || '/',
  });

  return router;
};

export const initYourWorkProjects = () => {
  const el = document.getElementById('js-your-work-projects-app');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { initialSort, programmingLanguages, emptyStateProjectsSvgPath, emptyStateSearchSvgPath } =
    convertObjectPropsToCamelCase(JSON.parse(appData));

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    router: createRouter(),
    apolloProvider,
    name: 'YourWorkProjectsRoot',
    provide: {
      initialSort,
      programmingLanguages,
      emptyStateProjectsSvgPath,
      emptyStateSearchSvgPath,
    },
    render(createElement) {
      return createElement(YourWorkProjectsApp);
    },
  });
};
