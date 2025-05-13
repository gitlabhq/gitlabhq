import { issuableInitialDataById, isLegacyIssueType } from '~/issues/show/utils/issuable_data';
import { WORK_ITEM_TYPE_NAME_ISSUE } from '~/work_items/constants';

const initLegacyIssuePage = async () => {
  const [{ initShow }] = await Promise.all([import('~/issues')]);
  initShow();
};

const initWorkItemPage = async () => {
  const [{ initWorkItemsRoot }] = await Promise.all([import('~/work_items')]);

  initWorkItemsRoot({ workItemType: WORK_ITEM_TYPE_NAME_ISSUE });
};

const issuableData = issuableInitialDataById('js-issuable-app');

if (
  !isLegacyIssueType(issuableData) &&
  (gon.features.workItemViewForIssues ||
    (gon.features.workItemsViewPreference && gon.current_user_use_work_items_view))
) {
  initWorkItemPage();
} else {
  initLegacyIssuePage();
}
