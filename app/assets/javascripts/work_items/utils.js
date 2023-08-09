import { WIDGET_TYPE_ASSIGNEES, WIDGET_TYPE_HIERARCHY, WIDGET_TYPE_LABELS } from './constants';

export const isAssigneesWidget = (widget) => widget.type === WIDGET_TYPE_ASSIGNEES;

export const isLabelsWidget = (widget) => widget.type === WIDGET_TYPE_LABELS;

export const findHierarchyWidgets = (widgets) =>
  widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY);

export const findHierarchyWidgetChildren = (workItem) =>
  findHierarchyWidgets(workItem?.widgets)?.children?.nodes || [];

const autocompleteSourcesPath = (autocompleteType, fullPath, workItemIid) => {
  return `${
    gon.relative_url_root || ''
  }/${fullPath}/-/autocomplete_sources/${autocompleteType}?type=WorkItem&type_id=${workItemIid}`;
};

export const autocompleteDataSources = (fullPath, iid) => ({
  labels: autocompleteSourcesPath('labels', fullPath, iid),
  members: autocompleteSourcesPath('members', fullPath, iid),
  commands: autocompleteSourcesPath('commands', fullPath, iid),
});

export const markdownPreviewPath = (fullPath, iid) =>
  `${
    gon.relative_url_root || ''
  }/${fullPath}/preview_markdown?target_type=WorkItem&target_id=${iid}`;
