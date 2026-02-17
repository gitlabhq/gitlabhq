import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ExploreProjectsApp from '~/explore/projects/components/app.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { EXPLORE_PROJECTS_TABS } from '~/explore/projects/constants';

Vue.use(VueRouter);

export const createRouter = (basePath) => {
  return new VueRouter({
    routes: [
      {
        name: 'root',
        path: '/',
        component: ExploreProjectsApp,
      },
      ...EXPLORE_PROJECTS_TABS.map(({ value }) => ({
        name: value,
        path: `/${value}`,
        component: ExploreProjectsApp,
      })),
    ],
    mode: 'history',
    base: basePath,
  });
};

export const initExploreProjects = () => {
  const el = document.getElementById('js-explore-projects');

  if (!el) return null;

  const { basePath, initialSort, programmingLanguages } = convertObjectPropsToCamelCase(el.dataset);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    router: createRouter(basePath),
    apolloProvider,
    name: 'ExploreProjectsRoot',
    render(createElement) {
      return createElement(ExploreProjectsApp, {
        props: {
          initialSort,
          programmingLanguages: JSON.parse(programmingLanguages),
        },
      });
    },
  });
};
