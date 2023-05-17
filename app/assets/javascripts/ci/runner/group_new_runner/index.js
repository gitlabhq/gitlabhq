import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import GroupNewRunnerApp from './group_new_runner_app.vue';

Vue.use(VueApollo);

export const initGroupNewRunner = (selector = '#js-group-new-runner') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { groupId } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(GroupNewRunnerApp, {
        props: {
          groupId,
        },
      });
    },
  });
};
