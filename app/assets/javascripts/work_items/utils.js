import { getIdFromGraphQLId } from '~/graphql_shared/utils';
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

export const formatAncestors = (workItem) =>
  findHierarchyWidgetAncestors(workItem).map((ancestor) => ({
    ...ancestor,
    icon: getWorkItemIcon(ancestor.workItemType?.iconName),
    href: ancestor.webUrl,
  }));

export const findHierarchyWidgetDefinition = (widgetDefinitions) =>
  widgetDefinitions?.find((widgetDefinition) => widgetDefinition.type === WIDGET_TYPE_HIERARCHY);

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
  return `${domain}/groups/${fullPath}/-/roadmap?epic_iid=${iid}`;
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
