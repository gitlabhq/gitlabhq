import produce from 'immer';
import VueApollo from 'vue-apollo';
import { concatPagination } from '@apollo/client/utilities';
import errorQuery from '~/boards/graphql/client/error.query.graphql';
import selectedBoardItemsQuery from '~/boards/graphql/client/selected_board_items.query.graphql';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import getIssueStateQuery from '~/issues/show/queries/get_issue_state.query.graphql';
import createDefaultClient from '~/lib/graphql';
import typeDefs from '~/work_items/graphql/typedefs.graphql';
import {
  WIDGET_TYPE_NOTES,
  WIDGET_TYPE_AWARD_EMOJI,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_CUSTOM_FIELDS,
  WIDGET_TYPE_LINKED_ITEMS,
  CUSTOM_FIELDS_TYPE_NUMBER,
  CUSTOM_FIELDS_TYPE_TEXT,
  CUSTOM_FIELDS_TYPE_SINGLE_SELECT,
  CUSTOM_FIELDS_TYPE_MULTI_SELECT,
} from '~/work_items/constants';

import isExpandedHierarchyTreeChildQuery from '~/work_items/graphql/client/is_expanded_hierarchy_tree_child.query.graphql';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import activeDiscussionQuery from '~/work_items/components/design_management/graphql/client/active_design_discussion.query.graphql';
import { updateNewWorkItemCache, workItemBulkEdit } from '~/work_items/graphql/resolvers';

export const config = {
  typeDefs,
  cacheConfig: {
    typePolicies: {
      Query: {
        fields: {
          isShowingLabels: {
            read(currentState) {
              return currentState ?? true;
            },
          },
          selectedBoardItems: {
            read(currentState) {
              return currentState ?? [];
            },
          },
          boardList: {
            keyArgs: ['id'],
          },
          epicBoardList: {
            keyArgs: ['id'],
          },
          isExpandedHierarchyTreeChild: (_, { variables, toReference }) =>
            toReference({ __typename: 'LocalWorkItemChildIsExpanded', id: variables.id }),
        },
      },
      MergeRequestConnection: {
        merge: true,
      },
      DesignManagement: {
        merge(existing = {}, incoming) {
          return { ...existing, ...incoming };
        },
      },
      Project: {
        fields: {
          projectMembers: {
            keyArgs: ['fullPath', 'search', 'relations', 'first'],
          },
        },
      },
      Namespace: {
        fields: {
          merge: true,
        },
      },
      WorkItemWidgetNotes: {
        fields: {
          // If we add any key args, the discussions field becomes discussions({"filter":"ONLY_ACTIVITY","first":10}) and
          // kills any possibility to handle it on the widget level without hardcoding a string.
          discussions: {
            keyArgs: false,
          },
        },
      },
      WorkItemWidgetAwardEmoji: {
        fields: {
          // If we add any key args, the awardEmoji field becomes awardEmoji({"first":10}) and
          // kills any possibility to handle it on the widget level without hardcoding a string.
          awardEmoji: {
            keyArgs: false,
          },
        },
      },
      WorkItemWidgetProgress: {
        fields: {
          progress: {
            // We want to show null progress as 0 as per https://gitlab.com/gitlab-org/gitlab/-/issues/386117
            read(existing) {
              return existing === null ? 0 : existing;
            },
          },
        },
      },
      DescriptionVersion: {
        fields: {
          startVersionId: {
            read() {
              // we need to set this when fetching the diff in the last 10 mins , the starting diff will be the very first one , so need to save it
              return '';
            },
          },
        },
      },
      WorkItemWidgetHierarchy: {
        fields: {
          // If we add any key args, the children field becomes children({"first":10}) and
          // kills any possibility to handle it on the widget level without hardcoding a string.
          children: {
            keyArgs: false,
          },
        },
      },
      WorkItem: {
        fields: {
          // @todo: Mocking CUSTOM_FIELDS widget while not suported by backend
          mockWidgets: {
            read() {
              return [
                {
                  __typename: 'LocalWorkItemCustomFields',
                  type: WIDGET_TYPE_CUSTOM_FIELDS,
                  customFieldValues: [
                    {
                      id: 'gid://gitlab/CustomFieldValue/1',
                      customField: {
                        id: '1-number',
                        fieldType: CUSTOM_FIELDS_TYPE_NUMBER,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Number custom field label',
                        __typename: 'LocalWorkItemCustomField',
                      },
                      value: 5,
                      __typename: 'LocalWorkItemNumberFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/2',
                      customField: {
                        id: '2-number',
                        fieldType: CUSTOM_FIELDS_TYPE_NUMBER,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Null Number custom field label',
                        __typename: 'LocalWorkItemCustomField',
                      },
                      value: null,
                      __typename: 'LocalWorkItemNumberFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/3',
                      customField: {
                        id: '1-text',
                        fieldType: CUSTOM_FIELDS_TYPE_TEXT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Text custom field label',
                        __typename: 'LocalWorkItemCustomField',
                      },
                      // eslint-disable-next-line @gitlab/require-i18n-strings
                      value: 'some text',
                      __typename: 'LocalWorkItemTextFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/4',
                      customField: {
                        id: '11-text',
                        fieldType: CUSTOM_FIELDS_TYPE_TEXT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Long Text custom field label',
                        __typename: 'LocalWorkItemCustomField',
                      },
                      value:
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        'some long long lo ng long long long long long long texttt  ng long long long long long long texttt  ng long long long long long long texttt ng long long long long texttt some long long long long long long long texttt some long long long long long long long texttt some long long long long long long long texttt some long long long long long long long texttt some long long long long long long long texttt some long long long long long long long texttt some long long long long long long long texttt some long long long long long long',
                      __typename: 'LocalWorkItemTextFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/5',
                      customField: {
                        id: '2-text',
                        fieldType: CUSTOM_FIELDS_TYPE_TEXT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Link Text custom field label',
                        __typename: 'LocalWorkItemCustomField',
                      },
                      value: 'https://gitlab.com/gitlab-org/gitlab/-/work_items/41',
                      __typename: 'LocalWorkItemTextFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/6',
                      customField: {
                        id: '3-text',
                        fieldType: CUSTOM_FIELDS_TYPE_TEXT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Null Text custom field label',
                        __typename: 'LocalWorkItemCustomField',
                      },
                      value: null,
                      __typename: 'LocalWorkItemTextFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/7',
                      customField: {
                        id: '4-text',
                        fieldType: CUSTOM_FIELDS_TYPE_TEXT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Empty string Text custom field label',
                        __typename: 'LocalWorkItemCustomField',
                      },
                      value: '',
                      __typename: 'LocalWorkItemTextFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/8',
                      customField: {
                        id: '1-select',
                        fieldType: CUSTOM_FIELDS_TYPE_SINGLE_SELECT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Single select custom field label',
                        selectOptions: [
                          {
                            id: 'select-1',
                            value:
                              // eslint-disable-next-line @gitlab/require-i18n-strings
                              'Option 1 is longlonglongonglonglonglonglonglong',
                          },
                          {
                            id: 'select-2',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 2',
                          },
                          {
                            id: 'select-3',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 3',
                          },
                        ],
                        __typename: 'LocalWorkItemCustomFieldSelect',
                      },
                      selectedOptions: [
                        {
                          id: 'select-1',
                          value:
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            'Option 1 is longlonglongonglonglonglonglonglong',
                        },
                      ],
                      __typename: 'LocalWorkItemSelectFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/9',
                      customField: {
                        id: '2-select',
                        fieldType: CUSTOM_FIELDS_TYPE_SINGLE_SELECT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Null Single select custom field label',
                        selectOptions: [
                          {
                            id: 'select-1',
                            value:
                              // eslint-disable-next-line @gitlab/require-i18n-strings
                              'Option 1 is long long lo ng long long long long long long',
                          },
                          {
                            id: 'select-2',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 2',
                          },
                          {
                            id: 'select-3',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 3',
                          },
                        ],
                        __typename: 'LocalWorkItemCustomFieldSelect',
                      },
                      selectedOptions: null,
                      __typename: 'LocalWorkItemSelectFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/10',
                      customField: {
                        id: '1-multi-select',
                        fieldType: CUSTOM_FIELDS_TYPE_MULTI_SELECT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Multi select custom field label',
                        selectOptions: [
                          {
                            id: 'select-1',
                            value:
                              // eslint-disable-next-line @gitlab/require-i18n-strings
                              'Option 1 is long long lo ng long long long long long long',
                          },
                          {
                            id: 'select-2',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 2',
                          },
                          {
                            id: 'select-3',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 3',
                          },
                        ],
                        __typename: 'LocalWorkItemCustomFieldSelect',
                      },
                      selectedOptions: [
                        {
                          id: 'select-1',
                          value:
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            'Option 1 is long long lo ng long long long long long long',
                        },
                        {
                          id: 'select-2',
                          // eslint-disable-next-line @gitlab/require-i18n-strings
                          value: 'Option 2',
                        },
                      ],
                      __typename: 'LocalWorkItemSelectFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/11',
                      customField: {
                        id: '2-multi-select',
                        fieldType: CUSTOM_FIELDS_TYPE_MULTI_SELECT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'Null Multi select custom field label',
                        selectOptions: [
                          {
                            id: 'select-1',
                            value:
                              // eslint-disable-next-line @gitlab/require-i18n-strings
                              'Option 1 is long long lo ng long long long long long long',
                          },
                          {
                            id: 'select-2',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 2',
                          },
                          {
                            id: 'select-3',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 3',
                          },
                        ],
                        __typename: 'LocalWorkItemCustomFieldSelect',
                      },
                      selectedOptions: null,
                      __typename: 'LocalWorkItemSelectFieldValue',
                    },
                    {
                      id: 'gid://gitlab/CustomFieldValue/12',
                      customField: {
                        id: '3-multi-select',
                        fieldType: CUSTOM_FIELDS_TYPE_MULTI_SELECT,
                        // eslint-disable-next-line @gitlab/require-i18n-strings
                        name: 'One selected Multi select custom field label',
                        selectOptions: [
                          {
                            id: 'select-1',
                            value:
                              // eslint-disable-next-line @gitlab/require-i18n-strings
                              'Option 1 is long long lo ng long long long long long long',
                          },
                          {
                            id: 'select-2',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 2',
                          },
                          {
                            id: 'select-3',
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            value: 'Option 3',
                          },
                        ],
                        __typename: 'LocalWorkItemCustomFieldSelect',
                      },
                      selectedOptions: [
                        {
                          id: 'select-1',
                          value:
                            // eslint-disable-next-line @gitlab/require-i18n-strings
                            'Option 1 is long long lo ng long long long long long long',
                        },
                      ],
                      __typename: 'LocalWorkItemSelectFieldValue',
                    },
                  ],
                },
              ];
            },
          },
          // widgets policy because otherwise the subscriptions invalidate the cache
          widgets: {
            merge(existing = [], incoming, context) {
              if (existing.length === 0) {
                return incoming;
              }
              return existing.map((existingWidget) => {
                const incomingWidget = incoming.find(
                  (w) => w.type && w.type === existingWidget.type,
                );

                // we want to concat next page of awardEmoji to the existing ones
                if (incomingWidget?.type === WIDGET_TYPE_AWARD_EMOJI && context.variables.after) {
                  // concatPagination won't work because we were placing new widget here so we have to do this manually
                  return {
                    ...incomingWidget,
                    awardEmoji: {
                      ...incomingWidget.awardEmoji,
                      nodes: [
                        ...existingWidget.awardEmoji.nodes,
                        ...incomingWidget.awardEmoji.nodes,
                      ],
                    },
                  };
                }

                // we want to concat next page of discussions to the existing ones
                if (incomingWidget?.type === WIDGET_TYPE_NOTES && context.variables.after) {
                  // concatPagination won't work because we were placing new widget here so we have to do this manually
                  return {
                    ...incomingWidget,
                    discussions: {
                      ...incomingWidget.discussions,
                      nodes: [
                        ...existingWidget.discussions.nodes,
                        ...incomingWidget.discussions.nodes,
                      ],
                    },
                  };
                }

                // we want to concat next page of children work items within Hierarchy widget to the existing ones
                if (
                  incomingWidget?.type === WIDGET_TYPE_HIERARCHY &&
                  context.variables.endCursor &&
                  incomingWidget.children?.nodes
                ) {
                  // concatPagination won't work because we were placing new widget here so we have to do this manually
                  return {
                    ...incomingWidget,
                    children: {
                      ...incomingWidget.children,
                      nodes: [...existingWidget.children.nodes, ...incomingWidget.children.nodes],
                    },
                  };
                }

                // this ensures that we don’t override linkedItems.workItem when updating parent
                if (incomingWidget?.type === WIDGET_TYPE_LINKED_ITEMS) {
                  if (!incomingWidget.linkedItems) {
                    return existingWidget;
                  }

                  const incomindNodes = incomingWidget.linkedItems?.nodes || [];
                  const existingNodes = existingWidget.linkedItems?.nodes || [];

                  const resultNodes = incomindNodes.map((incomingNode) => {
                    const existingNode =
                      existingNodes.find((n) => n.linkId === incomingNode.linkId) ?? {};
                    return { ...existingNode, ...incomingNode };
                  });

                  return {
                    ...incomingWidget,
                    linkedItems: {
                      ...incomingWidget.linkedItems,
                      nodes: resultNodes,
                    },
                  };
                }

                return { ...existingWidget, ...incomingWidget };
              });
            },
          },
        },
      },
      MemberInterfaceConnection: {
        fields: {
          nodes: concatPagination(),
        },
      },
      Group: {
        fields: {
          projects: {
            keyArgs: ['includeSubgroups', 'search'],
          },
          descendantGroups: {
            keyArgs: ['includeSubgroups', 'search'],
          },
        },
      },
      ProjectConnection: {
        fields: {
          nodes: concatPagination(),
        },
      },
      GroupConnection: {
        fields: {
          nodes: concatPagination(),
        },
      },
      MergeRequestApprovalState: {
        merge: true,
      },
      WorkItemType: {
        // this prevents child and parent work item types from overriding each other
        fields: {
          supportedConversionTypes: {
            merge(__, incoming) {
              return incoming;
            },
          },
          widgetDefinitions: {
            merge(existing = [], incoming) {
              if (existing.length === 0) {
                return incoming;
              }

              return existing.map((existingWidget) => {
                const incomingWidget = incoming.find(
                  (w) => w.type && w.type === existingWidget.type,
                );

                return { ...existingWidget, ...incomingWidget };
              });
            },
          },
        },
      },
    },
  },
};

export const resolvers = {
  Mutation: {
    updateIssueState: (_, { issueType = undefined, isDirty = false }, { cache }) => {
      const sourceData = cache.readQuery({ query: getIssueStateQuery });
      const data = produce(sourceData, (draftData) => {
        draftData.issueState = { issueType, isDirty };
      });
      cache.writeQuery({ query: getIssueStateQuery, data });
    },
    setActiveBoardItem(_, { boardItem, listId }, { cache }) {
      cache.writeQuery({
        query: activeBoardItemQuery,
        data: { activeBoardItem: { ...boardItem, listId } },
      });
      return { ...boardItem, listId };
    },
    setSelectedBoardItems(_, { itemId }, { cache }) {
      const sourceData = cache.readQuery({ query: selectedBoardItemsQuery });
      cache.writeQuery({
        query: selectedBoardItemsQuery,
        data: { selectedBoardItems: [...sourceData.selectedBoardItems, itemId] },
      });
      return [...sourceData.selectedBoardItems, itemId];
    },
    unsetSelectedBoardItems(_, _variables, { cache }) {
      cache.writeQuery({
        query: selectedBoardItemsQuery,
        data: { selectedBoardItems: [] },
      });
      return [];
    },
    setError(_, { error }, { cache }) {
      cache.writeQuery({
        query: errorQuery,
        data: { boardsAppError: error },
      });
      return error;
    },
    clientToggleListCollapsed(_, { list = {}, collapsed = false }) {
      return {
        list: {
          ...list,
          collapsed,
        },
      };
    },
    clientToggleEpicListCollapsed(_, { list = {}, collapsed = false }) {
      return {
        list: {
          ...list,
          collapsed,
        },
      };
    },
    setIsShowingLabels(_, { isShowingLabels }, { cache }) {
      cache.writeQuery({
        query: isShowingLabelsQuery,
        data: { isShowingLabels },
      });
      return isShowingLabels;
    },
    updateNewWorkItem(_, { input }, { cache }) {
      updateNewWorkItemCache(input, cache);
    },
    localWorkItemBulkUpdate(_, { input }) {
      return workItemBulkEdit(input);
    },
    toggleHierarchyTreeChild(_, { id, isExpanded = false }, { cache }) {
      cache.writeQuery({
        query: isExpandedHierarchyTreeChildQuery,
        variables: { id },
        data: {
          isExpandedHierarchyTreeChild: {
            id,
            isExpanded,
            __typename: 'LocalWorkItemChildIsExpanded',
          },
        },
      });
    },
    updateActiveDesignDiscussion: (_, { id = null, source }, { cache }) => {
      const data = {
        activeDesignDiscussion: {
          __typename: 'ActiveDesignDiscussion',
          id,
          source,
        },
      };

      cache.writeQuery({ query: activeDiscussionQuery, data });
    },
  },
};

export const defaultClient = createDefaultClient(resolvers, config);

export const apolloProvider = new VueApollo({
  defaultClient,
});
