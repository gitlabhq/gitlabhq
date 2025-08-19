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
    activityPath,
    assignedMergeRequestsPath,
    assignedWorkItemsPath,
    authoredWorkItemsPath,
    duoCodeReviewBotUsername,
    mergeRequestsReviewRequestedTitle,
    mergeRequestsYourMergeRequestsTitle,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      duoCodeReviewBotUsername,
      mergeRequestsReviewRequestedTitle,
      mergeRequestsYourMergeRequestsTitle,
    },
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    render(createElement) {
      return createElement(HomepageApp, {
        props: {
          reviewRequestedPath,
          activityPath,
          assignedMergeRequestsPath,
          assignedWorkItemsPath,
          authoredWorkItemsPath,
        },
      });
    },
  });
};
