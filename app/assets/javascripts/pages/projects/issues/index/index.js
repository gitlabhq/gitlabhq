import { initWorkItemsRoot } from '~/work_items';
import { initJiraIssuesImportStatusRoot } from '~/work_items/list';

(async () => {
  if (gon.features?.vue3MigrateWorkItems) {
    try {
      const { initWorkItemsRoot: initVue3WorkItemsRoot } = await import('~/work_items?vue3');
      initVue3WorkItemsRoot();
      return;
    } catch {
      // Fall back to Vue 2 if the Vue 3 bundle fails to load
    }
  }

  initWorkItemsRoot();
})();
initJiraIssuesImportStatusRoot();
