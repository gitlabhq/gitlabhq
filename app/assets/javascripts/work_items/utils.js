import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { queryToObject } from '~/lib/utils/url_utility';
import AccessorUtilities from '~/lib/utils/accessor';
import { parseBoolean } from '~/lib/utils/common_utils';

import {
  NEW_WORK_ITEM_IID,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_DESIGNS,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_NOTES,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WIDGET_TYPE_WEIGHT,
  WIDGET_TYPE_AWARD_EMOJI,
  WIDGET_TYPE_LINKED_ITEMS,
  ISSUABLE_EPIC,
  WORK_ITEMS_TYPE_MAP,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_ENUM_TEST_CASE,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  WORK_ITEM_TYPE_ENUM_REQUIREMENTS,
  NEW_WORK_ITEM_GID,
  DEFAULT_PAGE_SIZE_CHILD_ITEMS,
} from './constants';

export const isAssigneesWidget = (widget) => widget.type === WIDGET_TYPE_ASSIGNEES;

export const isHealthStatusWidget = (widget) => widget.type === WIDGET_TYPE_HEALTH_STATUS;

export const isLabelsWidget = (widget) => widget.type === WIDGET_TYPE_LABELS;

export const isMilestoneWidget = (widget) => widget.type === WIDGET_TYPE_MILESTONE;

export const isNotesWidget = (widget) => widget.type === WIDGET_TYPE_NOTES;

export const isStartAndDueDateWidget = (widget) => widget.type === WIDGET_TYPE_START_AND_DUE_DATE;

export const isWeightWidget = (widget) => widget.type === WIDGET_TYPE_WEIGHT;

export const findHierarchyWidgets = (widgets) =>
  widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY);

export const findLinkedItemsWidget = (workItem) =>
  workItem.widgets?.find((widget) => widget.type === WIDGET_TYPE_LINKED_ITEMS);

export const findAwardEmojiWidget = (workItem) =>
  workItem.widgets?.find((widget) => widget.type === WIDGET_TYPE_AWARD_EMOJI);

export const findHierarchyWidgetChildren = (workItem) =>
  findHierarchyWidgets(workItem?.widgets)?.children?.nodes || [];

export const findHierarchyWidgetAncestors = (workItem) =>
  findHierarchyWidgets(workItem?.widgets)?.ancestors?.nodes || [];

export const findDesignWidget = (widgets) =>
  widgets?.find((widget) => widget.type === WIDGET_TYPE_DESIGNS);

export const getWorkItemIcon = (icon) => {
  if (icon === ISSUABLE_EPIC) return WORK_ITEMS_TYPE_MAP[WORK_ITEM_TYPE_ENUM_EPIC].icon;
  return icon;
};

/**
 * TODO: Remove this method with https://gitlab.com/gitlab-org/gitlab/-/issues/479637
 * We're currently setting children count per page based on `DEFAULT_PAGE_SIZE_CHILD_ITEMS`
 * but we need to find an ideal page size that's usable and fast enough. In order to test
 * correct page size in production with actual data, this method allows us to set page
 * size using query param (while falling back to `DEFAULT_PAGE_SIZE_CHILD_ITEMS`).
 */
export const getDefaultHierarchyChildrenCount = () => {
  const { children_count } = queryToObject(window.location.search);
  return Number(children_count) || DEFAULT_PAGE_SIZE_CHILD_ITEMS;
};

export const formatAncestors = (workItem) =>
  findHierarchyWidgetAncestors(workItem).map((ancestor) => ({
    ...ancestor,
    icon: getWorkItemIcon(ancestor.workItemType?.iconName),
    href: ancestor.webUrl,
  }));

export const findHierarchyWidgetDefinition = (workItem) =>
  workItem.workItemType.widgetDefinitions?.find(
    (widgetDefinition) => widgetDefinition.type === WIDGET_TYPE_HIERARCHY,
  );

const autocompleteSourcesPath = ({ autocompleteType, fullPath, iid, workItemTypeId, isGroup }) => {
  const domain = gon.relative_url_root || '';
  const basePath = isGroup ? `groups/${fullPath}` : fullPath;

  const typeId =
    iid === NEW_WORK_ITEM_IID
      ? `work_item_type_id=${getIdFromGraphQLId(workItemTypeId)}`
      : `type_id=${iid}`;
  return `${domain}/${basePath}/-/autocomplete_sources/${autocompleteType}?type=WorkItem&${typeId}`;
};

export const autocompleteDataSources = ({ fullPath, iid, workItemTypeId, isGroup = false }) => ({
  labels: autocompleteSourcesPath({
    autocompleteType: 'labels',
    fullPath,
    iid,
    isGroup,
    workItemTypeId,
  }),
  members: autocompleteSourcesPath({
    autocompleteType: 'members',
    fullPath,
    iid,
    isGroup,
    workItemTypeId,
  }),
  commands: autocompleteSourcesPath({
    autocompleteType: 'commands',
    fullPath,
    iid,
    isGroup,
    workItemTypeId,
  }),
  issues: autocompleteSourcesPath({
    autocompleteType: 'issues',
    fullPath,
    iid,
    isGroup,
    workItemTypeId,
  }),
  mergeRequests: autocompleteSourcesPath({
    autocompleteType: 'merge_requests',
    fullPath,
    iid,
    isGroup,
    workItemTypeId,
  }),
  epics: autocompleteSourcesPath({
    autocompleteType: 'epics',
    fullPath,
    iid,
    workItemTypeId,
    isGroup,
  }),
});

export const markdownPreviewPath = ({ fullPath, iid, isGroup = false }) => {
  const domain = gon.relative_url_root || '';
  const basePath = isGroup ? `groups/${fullPath}` : fullPath;
  return `${domain}/${basePath}/-/preview_markdown?target_type=WorkItem&target_id=${iid}`;
};

export const isReference = (input) => {
  /**
   * The regular expression checks if the `value` is
   * a project work item or group work item.
   * e.g., gitlab-org/project-path#101 or gitlab-org&101
   * or #1234
   */

  return /^([\w-]+(?:\/[\w-]+)*)?[#&](\d+)$/.test(input);
};

export const sortNameAlphabetically = (a, b) => {
  return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
};

/**
 * Builds path to Roadmap page pre-filtered by
 * work item iid
 *
 * @param {string} fullPath the path to the group
 * @param {string} iid the iid of the work item
 */
export const workItemRoadmapPath = (fullPath, iid) => {
  const domain = gon.relative_url_root || '';
  // We're hard-coding the values of `layout` & `timeframe_range_type` as those exist in `ee/app/assets/javascripts/roadmap/constants.js`
  // and importing those here also requires a corresponding file in non-EE scope and that's overengineering a query param.
  // This won't be needed once https://gitlab.com/gitlab-org/gitlab/-/issues/353191 is resolved.
  return `${domain}/groups/${fullPath}/-/roadmap?epic_iid=${iid}&layout=MONTHS&timeframe_range_type=CURRENT_YEAR`;
};

/**
 * Builds unique path for new work item
 *
 * @param {string} fullPath the path to the namespace
 * @param {string} workItemType the type of work item
 */

export const newWorkItemFullPath = (fullPath, workItemType) => {
  if (!workItemType) return undefined;

  const workItemTypeLowercase = workItemType.split(' ').join('-').toLowerCase();
  // eslint-disable-next-line @gitlab/require-i18n-strings
  return `${fullPath}-${workItemTypeLowercase}-id`;
};

/**
 * Checks whether the work item type is a valid enum
 *
 * @param {string} workItemType
 */

export const isWorkItemItemValidEnum = (workItemType) => {
  return (
    [
      WORK_ITEM_TYPE_ENUM_EPIC,
      WORK_ITEM_TYPE_ENUM_INCIDENT,
      WORK_ITEM_TYPE_ENUM_ISSUE,
      WORK_ITEM_TYPE_ENUM_TASK,
      WORK_ITEM_TYPE_ENUM_TEST_CASE,
      WORK_ITEM_TYPE_ENUM_OBJECTIVE,
      WORK_ITEM_TYPE_ENUM_KEY_RESULT,
      WORK_ITEM_TYPE_ENUM_REQUIREMENTS,
    ].indexOf(workItemType) >= 0
  );
};

export const newWorkItemId = (workItemType) => {
  if (!workItemType) return undefined;

  const workItemTypeLowercase = workItemType.split(' ').join('-').toLowerCase();
  return `${NEW_WORK_ITEM_GID}-${workItemTypeLowercase}`;
};

export const saveShowLabelsToLocalStorage = (showLabelsLocalStorageKey, value) => {
  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(showLabelsLocalStorageKey, value);
  }
};

export const getShowLabelsFromLocalStorage = (showLabelsLocalStorageKey, defaultValue = true) => {
  if (AccessorUtilities.canUseLocalStorage()) {
    return parseBoolean(localStorage.getItem(showLabelsLocalStorageKey) ?? defaultValue);
  }
  return null;
};
