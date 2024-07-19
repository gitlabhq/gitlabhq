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
} from '~/work_items/constants';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import { updateNewWorkItemCache } from '~/work_items/graphql/resolvers';

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
        },
      },
      Project: {
        fields: {
          projectMembers: {
            keyArgs: ['fullPath', 'search', 'relations', 'first'],
          },
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
                if (incomingWidget?.type === WIDGET_TYPE_HIERARCHY && context.variables.endCursor) {
                  // concatPagination won't work because we were placing new widget here so we have to do this manually
                  return {
                    ...incomingWidget,
                    children: {
                      ...incomingWidget.children,
                      nodes: [...existingWidget.children.nodes, ...incomingWidget.children.nodes],
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
      BoardList: {
        fields: {
          issues: {
            keyArgs: ['filters'],
          },
        },
      },
      IssueConnection: {
        merge(existing = { nodes: [] }, incoming, { args }) {
          if (!args?.after) {
            return incoming;
          }
          return {
            ...incoming,
            nodes: [...existing.nodes, ...incoming.nodes],
          };
        },
      },
      EpicList: {
        fields: {
          epics: {
            keyArgs: ['filters'],
          },
        },
      },
      EpicConnection: {
        merge(existing = { nodes: [] }, incoming, { args }) {
          if (!args?.after) {
            return incoming;
          }
          return {
            ...incoming,
            nodes: [...existing.nodes, ...incoming.nodes],
          };
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
      Board: {
        fields: {
          epics: {
            keyArgs: ['boardId'],
          },
        },
      },
      BoardEpicConnection: {
        merge(existing = { nodes: [] }, incoming, { args }) {
          if (!args.after) {
            return incoming;
          }
          return {
            ...incoming,
            nodes: [...existing.nodes, ...incoming.nodes],
          };
        },
      },
      MergeRequestApprovalState: {
        merge: true,
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
  },
};

export const defaultClient = createDefaultClient(resolvers, config);

export const apolloProvider = new VueApollo({
  defaultClient,
});
