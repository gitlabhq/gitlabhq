import {
  WIDGET_TYPE_ASSIGNEES,
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

const autocompleteSourcesPath = ({ autocompleteType, fullPath, iid, isGroup }) => {
  const domain = gon.relative_url_root || '';
  const basePath = isGroup ? `groups/${fullPath}` : fullPath;
  return `${domain}/${basePath}/-/autocomplete_sources/${autocompleteType}?type=WorkItem&type_id=${iid}`;
};

export const autocompleteDataSources = ({ fullPath, iid, isGroup = false }) => ({
  labels: autocompleteSourcesPath({ autocompleteType: 'labels', fullPath, iid, isGroup }),
  members: autocompleteSourcesPath({ autocompleteType: 'members', fullPath, iid, isGroup }),
  commands: autocompleteSourcesPath({ autocompleteType: 'commands', fullPath, iid, isGroup }),
});

export const markdownPreviewPath = ({ fullPath, iid, isGroup = false }) => {
  const domain = gon.relative_url_root || '';
  const basePath = isGroup ? `groups/${fullPath}` : fullPath;
  return `${domain}/${basePath}/preview_markdown?target_type=WorkItem&target_id=${iid}`;
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
