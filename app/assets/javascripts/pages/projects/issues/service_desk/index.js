import { initWorkItemsRoot } from '~/work_items';
import { WORK_ITEM_TYPE_NAME_TICKET } from '~/work_items/constants';

(async () => {
  if (gon.features?.vue3MigrateWorkItems) {
    try {
      const { initWorkItemsRoot: initVue3WorkItemsRoot } = await import('~/work_items?vue3');
      initVue3WorkItemsRoot({ workItemType: WORK_ITEM_TYPE_NAME_TICKET });
      return;
    } catch {
      // Fall back to Vue 2 if the Vue 3 bundle fails to load
    }
  }

  initWorkItemsRoot({ workItemType: WORK_ITEM_TYPE_NAME_TICKET });
})();
