import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initBoards from '~/boards';

addShortcutsExtension(ShortcutsNavigation);
initBoards();

if (gon.features.workItemsViewPreference) {
  import(/* webpackChunkName: 'work_items_feedback' */ '~/work_items_feedback')
    .then(({ initWorkItemsFeedback }) => {
      initWorkItemsFeedback();
    })
    .catch({});
}
