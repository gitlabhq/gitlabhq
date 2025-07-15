import { issuableInitialDataById, isLegacyIssueType } from '~/issues/show/utils/issuable_data';

const initLegacyIssuePage = async () => {
  const [{ initShow }] = await Promise.all([import('~/issues')]);
  initShow();
};

const initWorkItemPage = async () => {
  const [{ initWorkItemsRoot }] = await Promise.all([import('~/work_items')]);

  initWorkItemsRoot();
};

const issuableData = issuableInitialDataById('js-issuable-app');

if (!isLegacyIssueType(issuableData) && gon.features.workItemViewForIssues) {
  initWorkItemPage();
} else {
  initLegacyIssuePage();
}
