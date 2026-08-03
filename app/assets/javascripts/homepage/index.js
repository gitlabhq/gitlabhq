import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
    lastPushEvent,
  } = el.dataset;

  // Parse lastPushEvent - it's already JSON string from backend
  const parsedLastPushEvent = lastPushEvent ? JSON.parse(lastPushEvent) : null;

  return initVueApp({
    el,
    name: 'HomepageAppRoot',
    provide: {
      duoCodeReviewBotUsername,
    },
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    component: HomepageApp,
    props: {
      reviewRequestedPath,
      activityPath,
      assignedMergeRequestsPath,
      assignedWorkItemsPath,
      authoredWorkItemsPath,
      lastPushEvent: parsedLastPushEvent,
    },
  });
};
