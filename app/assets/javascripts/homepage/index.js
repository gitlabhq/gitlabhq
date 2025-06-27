import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import HomepageApp from './components/homepage_app.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-homepage-app');

  if (!el) {
    return false;
  }

  const {
    reviewRequestedPath,
    assignedMergeRequestsPath,
    assignedWorkItemsPath,
    authoredWorkItemsPath,
    duoCodeReviewBotUsername,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      duoCodeReviewBotUsername,
    },
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    render(createElement) {
      return createElement(HomepageApp, {
        props: {
          reviewRequestedPath,
          assignedMergeRequestsPath,
          assignedWorkItemsPath,
          authoredWorkItemsPath,
        },
      });
    },
  });
};
