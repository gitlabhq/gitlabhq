import { issuableInitialDataById, isLegacyIssueType } from '~/issues/show/utils/issuable_data';

const initLegacyIssuePage = async () => {
  const [{ initShow }] = await Promise.all([import('~/issues')]);
  initShow();
};

const initWorkItemPage = async () => {
  if (gon.features?.vue3MigrateWorkItems) {
    try {
      const [{ initWorkItemsRoot }] = await Promise.all([import('~/work_items?vue3')]);
      initWorkItemsRoot();
      return;
    } catch {
      // Fall back to Vue 2 if the Vue 3 bundle fails to load
    }
  }

  const [{ initWorkItemsRoot }] = await Promise.all([import('~/work_items')]);
  initWorkItemsRoot();
};

const issuableData = issuableInitialDataById('js-issuable-app');

if (!isLegacyIssueType(issuableData)) {
  initWorkItemPage();
} else {
  initLegacyIssuePage();
}
