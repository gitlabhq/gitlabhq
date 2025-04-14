import { mountIssuesListApp } from '~/issues/list';
import { ISSUE_WIT_FEEDBACK_BADGE } from '~/work_items/constants';

mountIssuesListApp();

let feedback = {};

if (gon.features.workItemViewForIssues) {
  feedback = {
    ...ISSUE_WIT_FEEDBACK_BADGE,
  };
}

if (gon.features.workItemsViewPreference || gon.features.workItemViewForIssues) {
  import(/* webpackChunkName: 'work_items_feedback' */ '~/work_items_feedback')
    .then(({ initWorkItemsFeedback }) => {
      initWorkItemsFeedback(feedback);
    })
    .catch({});
}
