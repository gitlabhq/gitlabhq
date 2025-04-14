import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';
import ProjectRunnerShowApp from './project_runner_show_app.vue';

Vue.use(VueApollo);
Vue.use(VueRouter);

export const initProjectRunnerShow = (selector = '#js-project-runner-show') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(ProjectRunnerShowApp, {
        props: {
          runnerId,
        },
      });
    },
  });
};
