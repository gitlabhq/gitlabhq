import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import WorkItemFeedback from './components/work_item_feedback.vue';
import WorkItemViewToggle from './components/work_item_view_toggle.vue';

Vue.use(VueApollo);

export const initWorkItemsFeedback = ({
  feedbackIssue,
  feedbackIssueText,
  title,
  content,
  expiry,
  featureName,
} = {}) => {
  if (expiry) {
    const expiryDate = new Date(expiry);
    if (Date.now() > expiryDate) {
      return null;
    }
  }

  const el = document.getElementById('js-work-item-feedback');

  return new Vue({
    el,
    name: 'WorkItemFeedbackRoot',
    apolloProvider,
    provide: {
      feedbackIssue,
      feedbackIssueText,
      title,
      content,
      featureName,
    },
    render(h) {
      return h(feedbackIssue ? WorkItemFeedback : WorkItemViewToggle);
    },
  });
};
