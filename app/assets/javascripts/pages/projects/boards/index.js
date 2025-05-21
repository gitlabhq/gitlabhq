import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initBoards from '~/boards';
import { ISSUE_WIT_FEEDBACK_BADGE } from '~/work_items/constants';

addShortcutsExtension(ShortcutsNavigation);
initBoards();

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
