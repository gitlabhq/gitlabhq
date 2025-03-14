import { mountIssuesListApp } from '~/issues/list';

mountIssuesListApp();

if (gon.features.workItemsViewPreference) {
  import(/* webpackChunkName: 'work_items_feedback' */ '~/work_items_feedback')
    .then(({ initWorkItemsFeedback }) => {
      initWorkItemsFeedback();
    })
    .catch({});
}
