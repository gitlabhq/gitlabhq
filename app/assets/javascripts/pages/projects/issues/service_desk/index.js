import { initFilteredSearchServiceDesk, mountServiceDeskListApp } from '~/issues/service_desk';
import { initWorkItemsRoot } from '~/work_items';
import { WORK_ITEM_TYPE_NAME_TICKET } from '~/work_items/constants';

initFilteredSearchServiceDesk();
mountServiceDeskListApp();
initWorkItemsRoot({ workItemType: WORK_ITEM_TYPE_NAME_TICKET });
