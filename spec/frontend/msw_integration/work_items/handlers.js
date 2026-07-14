import { join } from 'node:path';
import { findCurrentUserTodosWidget } from '~/work_items/utils';
import { buildUpdateResponse, loadFixturesMap } from '../fixture_utils';

const FIXTURES_PATH = join('tmp/tests/frontend/fixtures-ee/graphql/work_items/integration/');

const fixtures = loadFixturesMap(FIXTURES_PATH);

export const labelsResponse = fixtures.projectLabels;
export const autocompleteUsersResponse = fixtures.workspaceAutocompleteUsersSearch;
export const milestonesResponse = fixtures.projectMilestones;
export const baseUpdateResponse = fixtures.updateWorkItem;
export const canCreateBranchResponse = fixtures.canCreateBranch;
export const workItemsFullResponse = fixtures.getWorkItemsFull;

// Award-emoji integration fixtures (Rails-generated with reactions present on the
// shared work item, so the whole detail view stays on one normalized entity).
export const namespaceWorkItemResponse = fixtures.namespaceWorkItem;
export const projectWorkItemAwardEmojisResponse = fixtures.projectWorkItemAwardEmojis;
export const workItemNotesByIidResponse = fixtures.workItemNotesByIid;

const { id, name } = fixtures.getWorkItemsRest.data.namespace;

const LINKABLE_WORK_ITEM = {
  id: 'gid://gitlab/WorkItem/99',
  iid: '99',
  title: 'Linkable test issue',
  confidential: false,
  webUrl: 'http://localhost/group1/project-1/-/work_items/99',
  namespace: {
    id: 'gid://gitlab/Namespaces::ProjectNamespace/8',
    fullPath: 'group1/project-1',
    __typename: 'Namespace',
  },
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/1',
    name: 'Issue',
    iconName: 'work-item-issue',
    __typename: 'WorkItemType',
  },
  __typename: 'WorkItem',
};

const GET_WORK_ITEMS_REST_GQL_MOCK = {
  data: {
    namespace: { id, fullPath: 'gitlab-org/gitlab', name, __typename: 'Namespace' },
  },
};

const linkedItemsWidget = (workItem) => workItem.widgets.find((w) => w.type === 'LINKED_ITEMS');

// The linked-items query fixtures have no nodes; seed one from the add-mutation
// fixtures so the relationships list renders a row on mount for the remove-path spec.
linkedItemsWidget(fixtures.workItemLinkedItems.data.namespace.workItem).linkedItems.nodes = [
  linkedItemsWidget(fixtures.addLinkedItems.data.workItemAddLinkedItems.workItem).linkedItems
    .nodes[0],
];
fixtures.workItemLinkedItemsFeatures.data.namespace.workItem.features.linkedItems.linkedItems.nodes =
  [
    fixtures.addLinkedItemsFeatures.data.workItemAddLinkedItems.workItem.features.linkedItems
      .linkedItems.nodes[0],
  ];

// Seed a pending to-do so the To-do toggle renders in "mark as done" state on the
// work item drawer, on both the legacy widgets path and the features path.
const PENDING_TODO = { id: 'gid://gitlab/Todo/1', state: 'pending', __typename: 'Todo' };

findCurrentUserTodosWidget(
  fixtures.namespaceWorkItem.data.namespace.workItem,
).currentUserTodos.nodes = [PENDING_TODO];
// The features fixture predates the currentUserTodos migration, so the feature
// field is absent; add it so the features path renders the toggle.
fixtures.namespaceWorkItemFeatures.data.namespace.workItem.features.currentUserTodos = {
  __typename: 'WorkItemWidgetCurrentUserTodos',
  currentUserTodos: { nodes: [PENDING_TODO], __typename: 'TodoConnection' },
};

const currentUserTodosUpdateResponse = ({ useWorkItemFeatures, workItemId }) => {
  const emptyTodos = { nodes: [], __typename: 'TodoConnection' };

  return {
    data: {
      workItemUpdate: {
        __typename: 'WorkItemUpdatePayload',
        errors: [],
        workItem: {
          __typename: 'WorkItem',
          id: workItemId,
          ...(useWorkItemFeatures
            ? {
                features: {
                  __typename: 'WorkItemFeatures',
                  currentUserTodos: {
                    __typename: 'WorkItemWidgetCurrentUserTodos',
                    currentUserTodos: emptyTodos,
                  },
                },
              }
            : {
                widgets: [
                  {
                    __typename: 'WorkItemWidgetCurrentUserTodos',
                    type: 'CURRENT_USER_TODOS',
                    currentUserTodos: emptyTodos,
                  },
                ],
              }),
        },
      },
    },
  };
};

export const GET_WORK_ITEMS_REST_ENDPOINT = {
  name: 'getWorkItemsRest',
  method: 'get',
  path: /\/api\/v4\/namespaces\/.*\/-\/work_items/,
  response: fixtures.restWorkItemsList,
  headers: { 'x-next-cursor': '', 'x-prev-cursor': '' },
};

const OPERATION_NAME_OVERRIDES = {
  workItemMetadataEE: fixtures.workItemMetadata,
  EEgetWorkItemStateCounts: fixtures.getWorkItemStateCounts,
  getWorkItemsFullEE: fixtures.getWorkItemsFull,
  getWorkItemsSlimEE: fixtures.getWorkItemsSlim,
  getWorkItemsRestEE: GET_WORK_ITEMS_REST_GQL_MOCK,
};

const FIXTURE_RESPONSES = {
  ...fixtures,
  ...OPERATION_NAME_OVERRIDES,
};

const STATIC_OPERATION_HANDLERS = Object.fromEntries(
  Object.entries(FIXTURE_RESPONSES).map(([operationName, fixture]) => [
    operationName,
    () => ({ data: fixture.data }),
  ]),
);

// The award-emoji body toggle resolves the cache from the server-returned
// `toggledOn`, so the handler tracks current-user reactions and flips per call.
// Reset between tests via resetAwardState().
let currentUserReactions = new Set();

export const resetAwardState = () => {
  currentUserReactions = new Set();
};

const awardEmojiMutationHandlers = {
  updateWorkItemAwardEmojiWidget: ({ variables }) => {
    const { awardableId, name: emojiName } = variables.input;
    const key = `${awardableId}:${emojiName}`;
    const toggledOn = !currentUserReactions.has(key);

    if (toggledOn) {
      currentUserReactions.add(key);
    } else {
      currentUserReactions.delete(key);
    }

    return {
      data: {
        awardEmojiToggle: { __typename: 'AwardEmojiTogglePayload', errors: [], toggledOn },
      },
    };
  },
  // Note reactions decide add-vs-remove and update the cache optimistically on the
  // client, so the acknowledgements are static.
  workItemNoteAddAwardEmoji: () => ({
    data: { awardEmojiAdd: { __typename: 'AwardEmojiAddPayload', errors: [] } },
  }),
  workItemNoteRemoveAwardEmoji: () => ({
    data: { awardEmojiRemove: { __typename: 'AwardEmojiRemovePayload', errors: [] } },
  }),
};

const MUTATION_OPERATION_HANDLERS = {
  ...awardEmojiMutationHandlers,
  createWorkItemNote: () => fixtures.createWorkItemNote,

  namespaceWorkItem: ({ variables }) =>
    variables.useWorkItemFeatures
      ? { data: fixtures.namespaceWorkItemFeatures.data }
      : { data: fixtures.namespaceWorkItem.data },

  projectWorkItems: () => ({
    data: {
      namespace: {
        id: 'gid://gitlab/Project/4',
        workItems: { nodes: [LINKABLE_WORK_ITEM], __typename: 'WorkItemConnection' },
        __typename: 'Project',
      },
    },
  }),

  workItemLinkedItems: ({ variables }) =>
    variables.useWorkItemFeatures
      ? { data: fixtures.workItemLinkedItemsFeatures.data }
      : { data: fixtures.workItemLinkedItems.data },

  addLinkedItems: ({ variables }) =>
    variables.useWorkItemFeatures
      ? { data: fixtures.addLinkedItemsFeatures.data }
      : { data: fixtures.addLinkedItems.data },

  removeLinkedItems: () => ({
    data: {
      workItemRemoveLinkedItems: {
        errors: [],
        message: 'Successfully unlinked',
        __typename: 'WorkItemRemoveLinkedItemsPayload',
      },
    },
  }),

  workItemUpdateCurrentUserTodos: ({ variables }) =>
    currentUserTodosUpdateResponse({
      useWorkItemFeatures: variables.useWorkItemFeatures,
      workItemId: variables.input.id,
    }),

  workItemSubscribe: ({ variables }) => ({
    data: {
      workItemSubscribe: {
        errors: [],
        workItem: {
          __typename: 'WorkItem',
          id: variables.input.id,
          widgets: [
            {
              type: 'NOTIFICATIONS',
              subscribed: variables.input.subscribed,
              __typename: 'WorkItemWidgetNotifications',
            },
          ],
        },
      },
    },
  }),

  savedViews: () => ({
    data: {
      namespace: {
        id: 'gid://gitlab/Group/1',
        savedViews: { nodes: [] },
      },
    },
  }),

  getUser: () => ({
    data: {
      currentUser: {
        id: 'gid://gitlab/User/1',
        callouts: {
          nodes: [{ featureName: 'work_items_onboarding_modal', __typename: 'UserCallout' }],
        },
        __typename: 'UserCore',
      },
    },
  }),

  getWorkItemsCountOnlyEE: () => ({
    data: {
      namespace: {
        id: 'gid://gitlab/Group/1',
        name: 'group1',
        workItems: { count: workItemsFullResponse.data.namespace.workItems.nodes.length },
      },
    },
  }),

  updateWorkItemListUserPreference: ({ variables }) => ({
    data: {
      workItemUserPreferenceUpdate: {
        errors: [],
        userPreferences: {
          displaySettings: variables.displaySettings,
          sort: variables.sort || null,
        },
      },
    },
  }),

  updateWorkItemsDisplaySettings: ({ variables }) => ({
    data: {
      userPreferencesUpdate: {
        userPreferences: {
          workItemsDisplaySettings: variables.input?.workItemsDisplaySettings || {},
        },
      },
    },
  }),

  workItemUpdate: ({ variables }) =>
    buildUpdateResponse({
      baseResponse: fixtures.updateWorkItem,
      labelsFixture: fixtures.updateWorkItemLabels,
      assigneesFixture: fixtures.updateWorkItemAssignees,
      milestoneFixture: fixtures.updateWorkItemMilestone,
      input: variables.input,
    }),
};

const OPERATION_HANDLERS = {
  ...STATIC_OPERATION_HANDLERS,
  ...MUTATION_OPERATION_HANDLERS,
};

export function handleWorkItemOperation({ operationName, variables, res, ctx }) {
  const handler = OPERATION_HANDLERS[operationName];

  if (!handler) {
    return null;
  }

  const payload = handler({ operationName, variables });

  return res(ctx.json(payload));
}

export const workItemRestEndpoints = [
  { method: 'get', path: /issues\/\d+\/can_create_branch/, response: fixtures.canCreateBranch },
  GET_WORK_ITEMS_REST_ENDPOINT,
];
