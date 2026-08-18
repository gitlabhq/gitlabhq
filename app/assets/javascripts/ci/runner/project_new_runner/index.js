import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import ProjectNewRunnerApp from './project_new_runner_app.vue';

Vue.use(VueApollo);

export const initProjectNewRunner = (selector = '#js-project-new-runner') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { projectId } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'ProjectNewRunnerAppRoot',
    apolloProvider,
    component: ProjectNewRunnerApp,
    props: {
      projectId,
    },
  });
};
