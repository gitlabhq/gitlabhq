import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { mountIssuesListApp, mountJiraIssuesListApp } from '~/issues/list';
import { initWorkItemsRoot } from '~/work_items';

mountIssuesListApp();
mountJiraIssuesListApp();
addShortcutsExtension(ShortcutsNavigation);

initWorkItemsRoot();

if (gon.features.workItemsViewPreference) {
  import(/* webpackChunkName: 'work_items_feedback' */ '~/work_items_feedback')
    .then(({ initWorkItemsFeedback }) => {
      initWorkItemsFeedback();
    })
    .catch({});
}
