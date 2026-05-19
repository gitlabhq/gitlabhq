import { join } from 'node:path';
import { buildUpdateResponse, loadFixturesMap } from '../fixture_utils';

const FIXTURES_PATH = join('tmp/tests/frontend/fixtures-ee/graphql/work_items/integration/');

const fixtures = loadFixturesMap(FIXTURES_PATH);

export const labelsResponse = fixtures.projectLabels;
export const autocompleteUsersResponse = fixtures.workspaceAutocompleteUsersSearch;
export const milestonesResponse = fixtures.projectMilestones;
export const baseUpdateResponse = fixtures.updateWorkItem;
export const canCreateBranchResponse = fixtures.canCreateBranch;
export const workItemsFullResponse = fixtures.getWorkItemsFull;

const { id, name } = fixtures.getWorkItemsRest.data.namespace;

const GET_WORK_ITEMS_REST_GQL_MOCK = {
  data: {
    namespace: { id, fullPath: 'gitlab-org/gitlab', name, __typename: 'Namespace' },
  },
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
  getWorkItemsRest: GET_WORK_ITEMS_REST_GQL_MOCK,
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

const MUTATION_OPERATION_HANDLERS = {
  createWorkItemNote: () => fixtures.createWorkItemNote,

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
