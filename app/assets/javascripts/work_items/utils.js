import { WIDGET_TYPE_HIERARCHY } from '~/work_items/constants';

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
