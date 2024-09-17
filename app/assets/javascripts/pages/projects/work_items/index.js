import { initWorkItemsRoot } from '~/work_items';

initWorkItemsRoot();

if (gon.features.work_items_view_preference) {
  import('~/work_items_feedback')
    .then(({ initWorkItemsFeedback }) => {
      initWorkItemsFeedback();
    })
    .catch({});
}
