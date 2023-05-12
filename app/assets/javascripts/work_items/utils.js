import { uniqueId } from 'lodash';
import {
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_CURRENT_USER_TODOS,
  CURRENT_USER_TODOS_TYPENAME,
  TODO_CONNECTION_TYPENAME,
  TODO_EDGE_TYPENAME,
  TODO_TYPENAME,
  WORK_ITEM_TYPENAME,
  WORK_ITEM_UPDATE_PAYLOAD_TYPENAME,
} from '~/work_items/constants';
import workItemQuery from './graphql/work_item.query.graphql';
import workItemByIidQuery from './graphql/work_item_by_iid.query.graphql';

export function getWorkItemQuery(isFetchedByIid) {
  return isFetchedByIid ? workItemByIidQuery : workItemQuery;
}

export const findHierarchyWidgets = (widgets) =>
  widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY);

export const findHierarchyWidgetChildren = (workItem) =>
  findHierarchyWidgets(workItem.widgets).children.nodes;

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

export const getWorkItemTodoOptimisticResponse = ({ workItem, pendingTodo }) => {
  const todo = pendingTodo
    ? [
        {
          node: {
            id: -uniqueId(),
            state: 'pending',
            __typename: TODO_TYPENAME,
          },
          __typename: TODO_EDGE_TYPENAME,
        },
      ]
    : [];
  return {
    workItemUpdate: {
      errors: [],
      workItem: {
        ...workItem,
        widgets: [
          {
            type: WIDGET_TYPE_CURRENT_USER_TODOS,
            currentUserTodos: {
              edges: todo,
              __typename: TODO_CONNECTION_TYPENAME,
            },
            __typename: CURRENT_USER_TODOS_TYPENAME,
          },
        ],
        __typename: WORK_ITEM_TYPENAME,
      },
      __typename: WORK_ITEM_UPDATE_PAYLOAD_TYPENAME,
    },
  };
};
