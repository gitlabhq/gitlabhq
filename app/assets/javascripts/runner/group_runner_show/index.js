import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import GroupRunnerShowApp from './group_runner_show_app.vue';

Vue.use(VueApollo);

export const initGroupRunnerShow = (selector = '#js-group-runner-show') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId, runnersPath, editGroupRunnerPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(GroupRunnerShowApp, {
        props: {
          runnerId,
          runnersPath,
          editGroupRunnerPath,
        },
      });
    },
  });
};
