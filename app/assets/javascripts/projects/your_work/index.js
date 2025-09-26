import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import routes from './routes';
import YourWorkProjectsApp from './components/app.vue';

Vue.use(VueRouter);

export const createRouter = (basePath) => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: basePath,
  });

  return router;
};

export const initYourWorkProjects = () => {
  const el = document.getElementById('js-your-work-projects-app');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { initialSort, programmingLanguages, basePath } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
  );

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    router: createRouter(basePath),
    apolloProvider,
    name: 'YourWorkProjectsRoot',
    render(createElement) {
      return createElement(YourWorkProjectsApp, { props: { initialSort, programmingLanguages } });
    },
  });
};
