import {
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_ROUTE_EPIC,
  WORK_ITEM_TYPE_ROUTE_ISSUE,
  WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
} from '../constants';

export const routeForWorkItemTypeName = (workItemTypeName) => {
  const wiTypeName = workItemTypeName?.toLowerCase();
  if (wiTypeName === WORK_ITEM_TYPE_NAME_ISSUE.toLowerCase()) {
    return WORK_ITEM_TYPE_ROUTE_ISSUE;
  }
  if (wiTypeName === WORK_ITEM_TYPE_NAME_EPIC.toLowerCase()) {
    return WORK_ITEM_TYPE_ROUTE_EPIC;
  }
  return WORK_ITEM_TYPE_ROUTE_WORK_ITEM;
};
