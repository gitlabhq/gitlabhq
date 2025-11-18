import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
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
    lastPushEvent,
    showFeedbackWidget,
  } = el.dataset;

  // Parse lastPushEvent - it's already JSON string from backend
  const parsedLastPushEvent = lastPushEvent ? JSON.parse(lastPushEvent) : null;

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
          lastPushEvent: parsedLastPushEvent,
          showFeedbackWidget: parseBoolean(showFeedbackWidget),
        },
      });
    },
  });
};
