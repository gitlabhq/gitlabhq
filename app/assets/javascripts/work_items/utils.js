import { escapeRegExp } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { queryToObject } from '~/lib/utils/url_utility';
import AccessorUtilities from '~/lib/utils/accessor';
import { parseBoolean } from '~/lib/utils/common_utils';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';

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
  WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
  NEW_WORK_ITEM_GID,
  DEFAULT_PAGE_SIZE_CHILD_ITEMS,
  STATE_CLOSED,
  WORK_ITEM_TYPE_VALUE_MAP,
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

export const findNotesWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_NOTES);

export const findStartAndDueDateWidget = (workItem) =>
  workItem.widgets?.find((widget) => widget.type === WIDGET_TYPE_START_AND_DUE_DATE);

export const findAwardEmojiWidget = (workItem) =>
  workItem.widgets?.find((widget) => widget.type === WIDGET_TYPE_AWARD_EMOJI);

export const findHierarchyWidgetChildren = (workItem) =>
  findHierarchyWidgets(workItem?.widgets)?.children?.nodes || [];

export const findHierarchyWidgetAncestors = (workItem) =>
  findHierarchyWidgets(workItem?.widgets)?.ancestors?.nodes || [];

export const findDesignWidget = (widgets) =>
  widgets?.find((widget) => widget.type === WIDGET_TYPE_DESIGNS);

export const convertTypeEnumToName = (workItemTypeEnum) =>
  Object.keys(WORK_ITEM_TYPE_VALUE_MAP).find(
    (value) => WORK_ITEM_TYPE_VALUE_MAP[value] === workItemTypeEnum,
  );

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
  milestones: autocompleteSourcesPath({
    autocompleteType: 'milestones',
    fullPath,
    iid,
    workItemTypeId,
    isGroup,
  }),
  iterations: autocompleteSourcesPath({
    autocompleteType: 'iterations',
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

// the path for creating a new work item of that type, e.g. /groups/gitlab-org/-/epics/new
export const newWorkItemPath = ({ fullPath, isGroup = false, workItemTypeName, query = '' }) => {
  const domain = gon.relative_url_root || '';
  const basePath = isGroup ? `groups/${fullPath}` : fullPath;
  const type =
    WORK_ITEMS_TYPE_MAP[workItemTypeName]?.routeParamName || WORK_ITEM_TYPE_ROUTE_WORK_ITEM;
  return `${domain}/${basePath}/-/${type}/new${query}`;
};

export const getDisplayReference = (workItemFullPath, workitemReference) => {
  // The reference is replaced by work item fullpath in case the project and group are same.
  // e.g., gitlab-org/gitlab-test#45 will be shown as #45
  if (new RegExp(`${workItemFullPath}#`, 'g').test(workitemReference)) {
    return workitemReference.replace(new RegExp(`${workItemFullPath}`, 'g'), '');
  }
  return workitemReference;
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

export const newWorkItemId = (workItemType) => {
  if (!workItemType) return undefined;

  const workItemTypeLowercase = workItemType.split(' ').join('-').toLowerCase();
  return `${NEW_WORK_ITEM_GID}-${workItemTypeLowercase}`;
};

export const saveToggleToLocalStorage = (key, value) => {
  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(key, value);
  }
};

export const getToggleFromLocalStorage = (key, defaultValue = true) => {
  if (AccessorUtilities.canUseLocalStorage()) {
    return parseBoolean(localStorage.getItem(key) ?? defaultValue);
  }
  return null;
};

/**
 * @param {{fullPath?: string, referencePath?: string}} activeItem
 * @param {string} fullPath
 * @param {string} issuableType
 * @returns {string}
 */
export const makeDrawerItemFullPath = (activeItem, fullPath, issuableType = TYPE_ISSUE) => {
  if (activeItem?.fullPath) {
    return activeItem.fullPath;
  }
  if (activeItem?.namespace?.fullPath) {
    return activeItem.namespace.fullPath;
  }

  const delimiter = issuableType === TYPE_EPIC ? '&' : '#';
  if (!activeItem?.referencePath) {
    return fullPath;
  }
  return activeItem.referencePath.split(delimiter)[0];
};

/**
 * since legacy epics don't have GID matching the work item ID, we need additional parameters
 * @param {{iid: string, id: string}} activeItem
 * @param {string} fullPath
 * @param {string} issuableType
 * @returns {{iid: string, full_path: string, id: number}}
 */
export const makeDrawerUrlParam = (activeItem, fullPath, issuableType = TYPE_ISSUE) => {
  return btoa(
    JSON.stringify({
      iid: activeItem.iid,
      full_path: makeDrawerItemFullPath(activeItem, fullPath, issuableType),
      id: getIdFromGraphQLId(activeItem.id),
    }),
  );
};

export const getNewWorkItemAutoSaveKey = (fullPath, workItemType) => {
  if (!workItemType || !fullPath) return '';
  return `new-${fullPath}-${workItemType.toLowerCase()}-draft`;
};

export const isItemDisplayable = (item, showClosed) => {
  return item.state !== STATE_CLOSED || (item.state === STATE_CLOSED && showClosed);
};

export const getItems = (showClosed) => {
  return (children) => {
    return children.filter((item) => isItemDisplayable(item, showClosed));
  };
};

export const canRouterNav = ({ fullPath, webUrl, isGroup, issueAsWorkItem }) => {
  const escapedFullPath = escapeRegExp(fullPath);
  // eslint-disable-next-line no-useless-escape
  const groupRegex = new RegExp(`groups\/${escapedFullPath}\/-\/(work_items|epics)\/\\d+`);
  // eslint-disable-next-line no-useless-escape
  const projectRegex = new RegExp(`${escapedFullPath}\/-\/(work_items|issues)\/\\d+`);
  const canGroupNavigate = groupRegex.test(webUrl) && isGroup;
  const canProjectNavigate = projectRegex.test(webUrl) && issueAsWorkItem;
  return canGroupNavigate || canProjectNavigate;
};

export const createBranchMRApiPathHelper = {
  canCreateBranch({ fullPath, workItemIid }) {
    return `/${fullPath}/-/issues/${workItemIid}/can_create_branch`;
  },
  createBranch({ fullPath, workItemIid, sourceBranch, targetBranch }) {
    return `/${fullPath}/-/branches?branch_name=${targetBranch}&format=json&issue_iid=${workItemIid}&ref=${sourceBranch}`;
  },
  createMR({ fullPath, workItemIid, sourceBranch, targetBranch }) {
    return `/${fullPath}/-/merge_requests/new?merge_request%5Bissue_iid%5D=${workItemIid}&merge_request%5Bsource_branch%5D=${sourceBranch}&merge_request%5Btarget_branch%5D=${targetBranch}`;
  },
  getRefs({ fullPath }) {
    return `/${fullPath}/refs?search=`;
  },
};

export const formatSelectOptionForCustomField = ({ id, value }) => ({
  text: value,
  value: id,
});
