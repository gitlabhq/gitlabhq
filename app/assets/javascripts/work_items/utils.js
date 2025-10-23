import { escapeRegExp, kebabCase } from 'lodash';
import { ref } from 'vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { joinPaths, queryToObject } from '~/lib/utils/url_utility';
import AccessorUtilities from '~/lib/utils/accessor';
import { parseBoolean } from '~/lib/utils/common_utils';
import { getDraft, updateDraft } from '~/lib/utils/autosave';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import Tracking from '~/tracking';

import {
  DEFAULT_PAGE_SIZE_CHILD_ITEMS,
  NAME_TO_ENUM_MAP,
  NAME_TO_ICON_MAP,
  NAME_TO_ROUTE_MAP,
  NEW_WORK_ITEM_GID,
  STATE_CLOSED,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_AWARD_EMOJI,
  WIDGET_TYPE_COLOR,
  WIDGET_TYPE_CRM_CONTACTS,
  WIDGET_TYPE_CURRENT_USER_TODOS,
  WIDGET_TYPE_CUSTOM_FIELDS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_DESIGNS,
  WIDGET_TYPE_DEVELOPMENT,
  WIDGET_TYPE_EMAIL_PARTICIPANTS,
  WIDGET_TYPE_ERROR_TRACKING,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_LINKED_ITEMS,
  WIDGET_TYPE_LINKED_RESOURCES,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_NOTES,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WIDGET_TYPE_STATUS,
  WIDGET_TYPE_TIME_TRACKING,
  WIDGET_TYPE_VULNERABILITIES,
  WIDGET_TYPE_WEIGHT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
} from './constants';

export const isAssigneesWidget = (widget) => widget.type === WIDGET_TYPE_ASSIGNEES;

export const isMilestoneWidget = (widget) => widget.type === WIDGET_TYPE_MILESTONE;

export const isNotesWidget = (widget) => widget.type === WIDGET_TYPE_NOTES;

export const isStatusWidget = (widget) => widget.type === WIDGET_TYPE_STATUS;

export const findAssigneesWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_ASSIGNEES);

export const findAwardEmojiWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_AWARD_EMOJI);

export const findColorWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_COLOR);

export const findCrmContactsWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_CRM_CONTACTS);

export const findCurrentUserTodosWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_CURRENT_USER_TODOS);

export const findCustomFieldsWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_CUSTOM_FIELDS);

export const findDescriptionWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_DESCRIPTION);

export const findDesignsWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_DESIGNS);

export const findDevelopmentWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_DEVELOPMENT);

export const findEmailParticipantsWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_EMAIL_PARTICIPANTS);

export const findErrorTrackingWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_ERROR_TRACKING);

export const findHealthStatusWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_HEALTH_STATUS);

export const findHierarchyWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY);

export const findIterationWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_ITERATION);

export const findLabelsWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_LABELS);

export const findLinkedItemsWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_LINKED_ITEMS);

export const findLinkedResourcesWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_LINKED_RESOURCES);

export const findMilestoneWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_MILESTONE);

export const findNotesWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_NOTES);

export const findStartAndDueDateWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_START_AND_DUE_DATE);

export const findStatusWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_STATUS);

export const findTimeTrackingWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_TIME_TRACKING);

export const findVulnerabilitiesWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_VULNERABILITIES);

export const findWeightWidget = (workItem) =>
  workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_WEIGHT);

export const findHierarchyWidgetChildren = (workItem) =>
  findHierarchyWidget(workItem)?.children?.nodes || [];

export const findHierarchyWidgetAncestors = (workItem) =>
  findHierarchyWidget(workItem)?.ancestors?.nodes || [];

export const formatLabelForListbox = (label) => ({
  text: label.title,
  value: label.id,
  color: label.color,
});

export const formatUserForListbox = (user) => ({
  ...user,
  text: user.name,
  value: user.id,
});

export const convertTypeEnumToName = (workItemTypeEnum) =>
  Object.keys(NAME_TO_ENUM_MAP).find((name) => NAME_TO_ENUM_MAP[name] === workItemTypeEnum);

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
    icon: NAME_TO_ICON_MAP[ancestor.workItemType?.name],
    href: ancestor.webUrl,
  }));

export const findHierarchyWidgetDefinition = (workItem) =>
  workItem.workItemType.widgetDefinitions?.find(
    (widgetDefinition) => widgetDefinition.type === WIDGET_TYPE_HIERARCHY,
  );

export const getParentGroupName = (namespaceFullName) => {
  const parts = namespaceFullName.split('/');
  // Gets the second-to-last item in the reference path
  return parts.length > 1 ? parts[parts.length - 2].trim() : '';
};

export const autocompleteDataSources = (autocompleteSourcesPaths = {}) => {
  const sources = {
    ...autocompleteSourcesPaths,
    statuses: true, // Include `statuses` as a property so GLFM autocompletion is enabled
  };

  // TODO - remove in %18.5. Adding this temporarily for multi-version compatibility
  if (autocompleteSourcesPaths.merge_requests) {
    sources.mergeRequests = autocompleteSourcesPaths.merge_requests;
  }

  return sources;
};

// the path for creating a new work item of that type, e.g. /groups/gitlab-org/-/epics/new
export const newWorkItemPath = ({ fullPath, isGroup = false, workItemType, query = '' }) => {
  const domain = gon.relative_url_root || '';
  const basePath = isGroup ? `groups/${fullPath}` : fullPath;
  // We have a special case to redirect to /groups/my-group/-/work_items/new
  // instead of /groups/my-group/-/issues/new
  const type =
    isGroup && workItemType === WORK_ITEM_TYPE_NAME_ISSUE
      ? WORK_ITEM_TYPE_ROUTE_WORK_ITEM
      : NAME_TO_ROUTE_MAP[workItemType] || WORK_ITEM_TYPE_ROUTE_WORK_ITEM;
  return `${domain}/${basePath}/-/${type}/new${query}`;
};

export const getDisplayReference = (workItemFullPath, workitemReference) => {
  // The full reference is replaced by IID reference in case the project and group are same.
  // e.g., gitlab-org/gitlab-test#45 will be shown as #45
  if (workitemReference.startsWith(`${workItemFullPath}#`)) {
    return workitemReference.replace(workItemFullPath, '');
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

export const getAutosaveKeyQueryParamString = () => {
  const allowedKeysInQueryParamString = [
    'vulnerability_id',
    'discussion_to_resolve',
    'issue[issue_type]',
    'issuable_template',
  ];
  const queryParams = new URLSearchParams(window.location.search);
  // Remove extra params from queryParams
  const allKeys = Array.from(queryParams.keys());
  for (const key of allKeys) {
    if (!allowedKeysInQueryParamString.includes(key)) {
      queryParams.delete(key);
    }
  }

  return queryParams.toString();
};

const getBaseNewWorkItemAutoSaveKey = ({ fullPath, context, relatedItemId }) => {
  const relatedId = getIdFromGraphQLId(relatedItemId);
  const queryParamString = getAutosaveKeyQueryParamString();

  let baseKey = `new-${fullPath}-${context}`;

  if (relatedId) {
    baseKey += `-related-id-${relatedId}`;
  }
  if (queryParamString) {
    baseKey += `-${queryParamString}`;
  }

  return baseKey;
};

export const getNewWorkItemAutoSaveKey = ({ fullPath, context, workItemType, relatedItemId }) => {
  if (!(fullPath && context && workItemType)) {
    throw new Error('Must provide fullPath && context && workItemType');
  }

  const baseKey = getBaseNewWorkItemAutoSaveKey({ fullPath, context, workItemType, relatedItemId });
  return `${baseKey}-${kebabCase(workItemType)}-draft`; // eslint-disable-line @gitlab/require-i18n-strings
};

export const getNewWorkItemWidgetsAutoSaveKey = ({ fullPath, context, relatedItemId }) => {
  if (!(fullPath && context)) {
    throw new Error('Must provide fullPath && context');
  }

  const baseKey = getBaseNewWorkItemAutoSaveKey({ fullPath, context, relatedItemId });
  return `${baseKey}-widgets-draft`;
};

export const getWorkItemWidgets = (draftData) => {
  if (!draftData?.workspace?.workItem) return {};

  const widgets = {};
  for (const widget of draftData.workspace.workItem.widgets || []) {
    if (widget.type) {
      widgets[widget.type] = widget;
    }
  }
  widgets.TITLE = draftData.workspace.workItem.title;
  widgets.TYPE = draftData.workspace.workItem.workItemType;

  return widgets;
};

export const updateDraftWorkItemType = ({ fullPath, context, workItemType, relatedItemId }) => {
  const widgetsAutosaveKey = getNewWorkItemWidgetsAutoSaveKey({
    fullPath,
    context,
    relatedItemId,
  });
  const sharedCacheWidgets = JSON.parse(getDraft(widgetsAutosaveKey)) || {};
  sharedCacheWidgets.TYPE = workItemType;
  updateDraft(widgetsAutosaveKey, JSON.stringify(sharedCacheWidgets));
};

export const getDraftWorkItemType = ({ fullPath, context, relatedItemId }) => {
  const widgetsAutosaveKey = getNewWorkItemWidgetsAutoSaveKey({
    fullPath,
    context,
    relatedItemId,
  });
  const sharedCacheWidgets = JSON.parse(getDraft(widgetsAutosaveKey)) || {};
  return sharedCacheWidgets.TYPE;
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
    return joinPaths(
      gon.relative_url_root || '',
      `/${fullPath}/-/issues/${workItemIid}/can_create_branch`,
    );
  },
  createBranch(fullPath) {
    return joinPaths(gon.relative_url_root || '', `/${fullPath}/-/branches`);
  },
  createMR({ fullPath, workItemIid, sourceBranch, targetBranch }) {
    let url = joinPaths(
      gon.relative_url_root || '',
      `/${fullPath}/-/merge_requests/new?merge_request%5Bissue_iid%5D=${workItemIid}&merge_request%5Bsource_branch%5D=${encodeURIComponent(sourceBranch)}`,
    );
    if (targetBranch) {
      url += `&merge_request%5Btarget_branch%5D=${encodeURIComponent(targetBranch)}`;
    }
    return url;
  },
  getRefs({ fullPath }) {
    return joinPaths(gon.relative_url_root || '', `/${fullPath}/refs?search=`);
  },
};

export const formatSelectOptionForCustomField = ({ id, value }) => ({
  text: value,
  value: id,
});

/**
 * This function takes the `descriptionHtml` property of a work item and updates any `<details>`
 * elements within it with an `open=true` attribute to match the current state in the DOM.
 *
 * This is necessary for scenarios such as toggling a checkbox with an opened `<details>` element,
 * which causes the `<details>` element to close when the frontend receives the backend response.
 *
 * @param {HTMLElement} element DOM element containing <details> elements
 * @param {string} descriptionHtml The incoming HTML description
 * @returns {string|null} The updated HTML for the incoming description that preserves the state of the <details> elements
 */
export const preserveDetailsState = (element, descriptionHtml) => {
  const previousDetails = Array.from(element.getElementsByTagName('details'));
  if (!previousDetails.some((details) => details.open)) {
    return null;
  }

  const nextTemplate = document.createElement('div');
  nextTemplate.innerHTML = descriptionHtml; // eslint-disable-line no-unsanitized/property
  const nextDetails = nextTemplate.getElementsByTagName('details');
  if (previousDetails.length !== nextDetails.length) {
    return null;
  }

  Array.from(nextDetails).forEach((details, i) => {
    if (previousDetails[i].open) {
      details.setAttribute('open', 'true');
    }
  });
  return nextTemplate.innerHTML;
};

export const activeWorkItemIds = ref([]);

export const getWorkItemTypeAllowedStatusMap = (workItemTypeNodes) => {
  const workItemTypeAllowedStatusMap = {};

  workItemTypeNodes.forEach((workItemType) => {
    const statuses = workItemType.widgetDefinitions?.find(isStatusWidget)?.allowedStatuses;
    if (statuses) {
      workItemTypeAllowedStatusMap[workItemType.name.toUpperCase()] = statuses;
    }
  });

  return workItemTypeAllowedStatusMap;
};

/**
 * Unified method for sending tracking events for work item CRUD component collapse/expand toggles
 * @param {string} action
 */
export function trackCrudCollapse(action) {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const category = 'Work item widget collapse';

  Tracking.event(category, action);
}
