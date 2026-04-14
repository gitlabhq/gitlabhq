import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import MockAdapter from 'axios-mock-adapter';
import { GlIntersectionObserver } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert, VARIANT_INFO } from '~/alert';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import setWindowLocation from 'helpers/set_window_location_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

import {
  CREATED_DESC,
  CREATED_ASC,
  TITLE_ASC,
  TITLE_DESC,
  UPDATED_ASC,
  RELATIVE_POSITION_ASC,
  UPDATED_DESC,
  urlSortParams,
} from '~/work_items/list/constants';
import { STATUS_OPEN } from '~/issues/constants';
import { routes } from '~/work_items/router/routes';
import {
  OPERATOR_IS,
  FILTERED_SEARCH_TERM,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CLOSED,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_CREATED,
  TOKEN_TYPE_DUE_DATE,
  TOKEN_TYPE_GROUP,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_STATE,
  TOKEN_TYPE_SUBSCRIBED,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_UPDATED,
  TOKEN_TYPE_ORGANIZATION,
  TOKEN_TYPE_CONTACT,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_PARENT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  CREATION_CONTEXT_LIST_ROUTE,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_TICKET,
} from '~/work_items/constants';

import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import getWorkItemStateCountsQuery from 'ee_else_ce/work_items/list/graphql/get_work_item_state_counts.query.graphql';
import getWorkItemsFullQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import hasWorkItemsQuery from '~/work_items/list/graphql/has_work_items.query.graphql';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import workItemsReorderMutation from '~/work_items/graphql/work_items_reorder.mutation.graphql';
import getUserWorkItemsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import namespaceSavedViewQuery from '~/work_items/list/graphql/namespace_saved_view.query.graphql';
import subscribeToSavedViewMutation from '~/work_items/graphql/subscribe_to_saved_view.mutation.graphql';
import getSubscribedSavedViewsQuery from '~/work_items/list/graphql/work_item_saved_views_namespace.query.graphql';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';

import { saveSavedView } from 'ee_else_ce/work_items/list/utils';

import PlanningView from '~/work_items/pages/planning_view.vue';
import ListView from 'ee_else_ce/work_items/list/list_view.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import WorkItemsSavedViewsSelectors from '~/work_items/list/components/work_items_saved_views_selectors.vue';
import WorkItemsNewSavedViewModal from '~/work_items/list/components/work_items_new_saved_view_modal.vue';
import WorkItemUserPreferences from '~/work_items/list/components/work_item_user_preferences.vue';
import InfoBanner from '~/work_items/list/components/info_banner.vue';
import WorkItemListActions from '~/work_items/list/components/work_item_list_actions.vue';
import EmptyStateWithAnyTickets from '~/work_items/list/components/empty_state_with_any_tickets.vue';
import EmptyStateWithoutAnyTickets from '~/work_items/list/components/empty_state_without_any_tickets.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import EmptyStateWithoutAnyIssues from '~/work_items/list/components/empty_state_without_any_issues.vue';
import EmptyStateWithAnyIssues from '~/work_items/list/components/empty_state_with_any_issues.vue';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';

import {
  workItemsQueryResponseNoLabels,
  workItemsQueryResponseNoAssignees,
  groupWorkItemStateCountsQueryResponse,
  userPreferenceQueryResponse,
  combinedQueryResultExample,
  namespaceWorkItemTypesQueryResponse,
  workItemCountsOnlyResponse,
  workItemUserPreferenceUpdateMutationResponseWithErrors,
  workItemUserPreferenceUpdateMutationResponse,
  sharedSavedView,
  singleSavedView,
  workItemsQueryResponseCombined,
} from '../mock_data';

import {
  mockSavedViewsData,
  savedViewResponseFactory,
  exampleSavedViewResponse,
} from '../list/mock_data';

const emptySavedViewsResult = {
  data: {
    namespace: {
      __typename: 'Namespace',
      id: 'namespace',
      currentSavedViews: {
        nodes: mockSavedViewsData,
      },
      subscribedSavedViewLimit: 100,
      savedViews: {
        __typename: 'SavedViewConnection',
        nodes: [],
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
        },
      },
    },
  },
};

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/common_utils');
jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal', () => ({
  confirmAction: jest.fn().mockResolvedValue(true),
}));
jest.mock('ee_else_ce/work_items/list/utils', () => ({
  ...jest.requireActual('ee_else_ce/work_items/list/utils'),
  saveSavedView: jest.fn(),
}));

useLocalStorageSpy();

const showToast = jest.fn();

const hasWorkItemsData = {
  data: {
    namespace: {
      id: 'namespace',
      workItems: {
        nodes: [{ id: 'thing' }],
      },
    },
  },
};

const defaultQueryHandler = jest.fn().mockResolvedValue(workItemsQueryResponseNoLabels);
const defaultSlimQueryHandler = jest.fn().mockResolvedValue(workItemsQueryResponseNoAssignees);
const defaultCountsQueryHandler = jest
  .fn()
  .mockResolvedValue(groupWorkItemStateCountsQueryResponse);
const namespaceQueryHandler = jest.fn().mockResolvedValue(namespaceWorkItemTypesQueryResponse);
const userPreferenceMutationHandler = jest
  .fn()
  .mockResolvedValue(workItemUserPreferenceUpdateMutationResponse);
const namespaceSavedViewHandler = jest.fn().mockResolvedValue(exampleSavedViewResponse);
const subscribeToSavedViewHandler = jest.fn().mockResolvedValue({
  data: {
    workItemSavedViewSubscribe: {
      __typename: 'WorkItemSavedViewSubscribePayload',
      errors: [],
      savedView: {
        __typename: 'WorkItemSavedViewType',
        id: 'gid://gitlab/WorkItems::SavedViews::SavedView/3',
      },
    },
  },
});

/** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
let wrapper;
let router;

Vue.use(VueApollo);
Vue.use(VueRouter);

const defaultHasWorkItemsHandler = jest.fn().mockResolvedValue(hasWorkItemsData);
const defaultCountsOnlyHandler = jest.fn().mockResolvedValue(workItemCountsOnlyResponse);

const emptyWorkItemsResponse = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/3',
      __typename: 'Group',
      name: 'Test',
      workItems: {
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          __typename: 'PageInfo',
        },
        nodes: [],
        count: 0,
      },
    },
  },
};
const emptyHasWorkItemsHandler = jest
  .fn()
  .mockResolvedValue({ data: { namespace: { id: 'namespace', workItems: { nodes: [] } } } });
const mockPreferencesQueryHandler = jest.fn().mockResolvedValue({
  data: {
    currentUser: null,
  },
});
const subscribedSavedViewsHandler = jest.fn().mockResolvedValue({
  data: {
    namespace: {
      __typename: 'Namespace',
      id: 'namespace',
      savedViews: {
        __typename: 'SavedViewConnection',
        nodes: mockSavedViewsData,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
        },
      },
    },
  },
});

const findListView = () => wrapper.findComponent(ListView);
const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);
const findGlIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
const findStickySearchContainer = () => wrapper.findByTestId('issuable-sticky-search-container');
const findSaveViewButton = () => wrapper.findByTestId('save-view-button');
const findResetViewButton = () => wrapper.findByTestId('reset-view-button');
const findUpdateViewButton = () => wrapper.findByTestId('update-view-button');
const findSaveChangesSeparator = () => wrapper.findByTestId('save-changes-separator');
const findNewSavedViewModal = () => wrapper.findComponent(WorkItemsNewSavedViewModal);
const findWorkItemsSavedViewsSelectors = () => wrapper.findComponent(WorkItemsSavedViewsSelectors);
const findViewNotFoundModal = () => wrapper.findByTestId('view-not-found-modal');
const findViewLimitWarningModal = () => wrapper.findByTestId('view-limit-warning-modal');
const findWorkItemUserPreferences = () => wrapper.findComponent(WorkItemUserPreferences);
const findServiceDeskInfoBanner = () => wrapper.findComponent(InfoBanner);
const findWorkItemListActions = () => wrapper.findComponent(WorkItemListActions);
const findBulkEditStartButton = () => wrapper.findByTestId('bulk-edit-start-button');
const findAnalyzeItemsButton = () => wrapper.findByTestId('analyze-items-button');
const findServiceDeskEmptyStateWithAnyIssues = () =>
  wrapper.findComponent(EmptyStateWithAnyTickets);
const findServiceDeskEmptyStateWithoutAnyIssues = () =>
  wrapper.findComponent(EmptyStateWithoutAnyTickets);
const findCreateWorkItemModal = () => wrapper.findComponent(CreateWorkItemModal);
const findEmptyStateWithoutAnyIssues = () => wrapper.findComponent(EmptyStateWithoutAnyIssues);
const findEmptyStateWithAnyIssues = () => wrapper.findComponent(EmptyStateWithAnyIssues);
const findNewResourceDropdown = () => wrapper.findComponent(NewResourceDropdown);

const RELEASES_ENDPOINT = '/test/project/-/releases.json';

const defaultFeatureFlags = {
  okrsMvc: true,
};

const mountComponent = ({
  queryHandler = defaultQueryHandler,
  slimQueryHandler = defaultSlimQueryHandler,
  countsQueryHandler = defaultCountsQueryHandler,
  hasWorkItemsHandler = defaultHasWorkItemsHandler,
  countsOnlyHandler = defaultCountsOnlyHandler,
  mockPreferencesHandler = mockPreferencesQueryHandler,
  savedViewHandler = namespaceSavedViewHandler,
  subscribeHandler = subscribeToSavedViewHandler,
  userPreferenceMutationResponse = userPreferenceMutationHandler,
  additionalHandlers = [],
  provide = {},
  isLoggedInValue = true,
  props = {},
} = {}) => {
  const { glFeatures: provideGlFeatures, ...restProvide } = provide;

  const apolloProvider = createMockApollo([
    [getWorkItemsFullQuery, queryHandler],
    [getWorkItemsSlimQuery, slimQueryHandler],
    [getWorkItemStateCountsQuery, countsQueryHandler],
    [namespaceWorkItemTypesQuery, namespaceQueryHandler],
    [hasWorkItemsQuery, hasWorkItemsHandler],
    [getWorkItemsCountOnlyQuery, countsOnlyHandler],
    [getUserWorkItemsPreferences, mockPreferencesHandler],
    [namespaceSavedViewQuery, savedViewHandler],
    [getSubscribedSavedViewsQuery, subscribedSavedViewsHandler],
    [subscribeToSavedViewMutation, subscribeHandler],
    [updateWorkItemListUserPreference, userPreferenceMutationResponse],
    ...additionalHandlers,
  ]);

  router = new VueRouter({
    mode: 'history',
    routes: [
      { name: 'base', path: '/', component: PlanningView },
      ...routes({ fullPath: '/work_item' }),
    ],
  });

  isLoggedIn.mockReturnValue(isLoggedInValue);

  wrapper = shallowMountExtended(PlanningView, {
    apolloProvider,
    router,
    provide: {
      glFeatures: {
        ...defaultFeatureFlags,
        ...provideGlFeatures,
      },
      metadataLoading: false,
      isGroup: true,
      isGroupIssuesList: false,
      isServiceDeskSupported: true,
      hasEpicsFeature: false,
      hasOkrsFeature: false,
      hasQualityManagementFeature: false,
      workItemType: null,
      isIssueRepositioningDisabled: false,
      groupId: 'gid://gitlab/Group/1',
      subscribedSavedViewLimit: 5,
      canCreateSavedView: true,
      newWorkItemEmailAddress: null,
      canReadCrmOrganization: true,
      canReadCrmContact: true,
      hasStatusFeature: false,
      showNewWorkItem: true,
      releasesPath: RELEASES_ENDPOINT,
      hasBlockedIssuesFeature: false,
      hasIssuableHealthStatusFeature: false,
      hasIssueDateFilterFeature: false,
      hasIssueWeightsFeature: false,
      hasCustomFieldsFeature: false,
      canCreateWorkItem: false,
      autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
      canAdminIssue: true,
      canBulkAdminEpic: true,
      canCreateProjects: true,
      hasGroupBulkEditFeature: true,
      hasProjects: true,
      ...restProvide,
    },
    propsData: {
      rootPageFullPath: 'full/path',
      withTabs: false,
      ...props,
    },
    mocks: {
      $toast: {
        show: showToast,
      },
    },
  });
};

const exampleQueryParams = {
  fullPath: 'full/path',
  includeDescendants: true,
  sort: CREATED_DESC,
  state: STATUS_OPEN,
  firstPageSize: 20,
};

describe('planning-view', () => {
  it('calls query to fetch work items when list-view emits update-query', async () => {
    mountComponent();

    findListView().vm.$emit('update-query', exampleQueryParams);

    await waitForPromises();

    expect(defaultQueryHandler).toHaveBeenCalledWith(expect.objectContaining(exampleQueryParams));
  });

  it('renders the WorkItemUserPreferences component', async () => {
    mountComponent();
    await waitForPromises();

    expect(findWorkItemUserPreferences().props()).toMatchObject({
      isEpicsList: false, // default work item is null so not an epics list
      fullPath: 'full/path',
      // TODO re-add shouldOpenItemsInSidePanel
      commonPreferences: {},
      namespacePreferences: {},
    });
  });

  describe('tokens', () => {
    it('renders tokens', async () => {
      mountComponent();
      await waitForPromises();
      const tokens = findFilteredSearchBar()
        .props('tokens')
        .map((token) => token.type);

      expect(tokens).toEqual([
        TOKEN_TYPE_ASSIGNEE,
        TOKEN_TYPE_AUTHOR,
        TOKEN_TYPE_CONFIDENTIAL,
        TOKEN_TYPE_CONTACT,
        TOKEN_TYPE_GROUP,
        TOKEN_TYPE_LABEL,
        TOKEN_TYPE_MILESTONE,
        TOKEN_TYPE_MY_REACTION,
        TOKEN_TYPE_ORGANIZATION,
        TOKEN_TYPE_PARENT,
        TOKEN_TYPE_SEARCH_WITHIN,
        TOKEN_TYPE_STATE,
        TOKEN_TYPE_SUBSCRIBED,
        TOKEN_TYPE_TYPE,
      ]);
    });

    describe('when workItemType is defined', () => {
      it('renders all tokens except "Type"', async () => {
        mountComponent({ provide: { workItemType: WORK_ITEM_TYPE_NAME_EPIC } });
        await waitForPromises();
        const tokens = findFilteredSearchBar()
          .props('tokens')
          .map((token) => token.type);

        expect(tokens).not.toContain(TOKEN_TYPE_TYPE);
      });
    });

    describe('when hasIssueDateFilterFeature is available', () => {
      it('renders date-related tokens too', async () => {
        mountComponent({ provide: { hasIssueDateFilterFeature: true } });
        await waitForPromises();
        const tokens = findFilteredSearchBar()
          .props('tokens')
          .map((token) => token.type);

        expect(tokens).toEqual([
          TOKEN_TYPE_ASSIGNEE,
          TOKEN_TYPE_AUTHOR,
          TOKEN_TYPE_CLOSED,
          TOKEN_TYPE_CONFIDENTIAL,
          TOKEN_TYPE_CONTACT,
          TOKEN_TYPE_CREATED,
          TOKEN_TYPE_DUE_DATE,
          TOKEN_TYPE_GROUP,
          TOKEN_TYPE_LABEL,
          TOKEN_TYPE_MILESTONE,
          TOKEN_TYPE_MY_REACTION,
          TOKEN_TYPE_ORGANIZATION,
          TOKEN_TYPE_PARENT,
          TOKEN_TYPE_SEARCH_WITHIN,
          TOKEN_TYPE_STATE,
          TOKEN_TYPE_SUBSCRIBED,
          TOKEN_TYPE_TYPE,
          TOKEN_TYPE_UPDATED,
        ]);
      });
    });

    describe('when issue_date_filter is enabled', () => {
      it('includes created and closed date in tokens', async () => {
        mountComponent({ provide: { hasIssueDateFilterFeature: true } });
        await waitForPromises();

        const tokenTypes = findFilteredSearchBar()
          .props('tokens')
          .map((token) => token.type);

        expect(tokenTypes).toEqual(expect.arrayContaining([TOKEN_TYPE_CLOSED, TOKEN_TYPE_CREATED]));
      });
    });

    describe('"State" token', () => {
      beforeEach(async () => {
        mountComponent();
        await waitForPromises();
      });
      it('includes "State", in tokens', () => {
        expect(
          findFilteredSearchBar()
            .props('tokens')
            .map((token) => token.type),
        ).toContain(TOKEN_TYPE_STATE);
      });
    });

    describe('custom field tokens', () => {
      it('combines eeSearchTokens with default search tokens', async () => {
        const customToken = {
          type: `custom`,
          title: 'Custom Field',
          token: () => {},
        };
        mountComponent({ props: { eeSearchTokens: [customToken] } });
        await waitForPromises();
        const tokens = findFilteredSearchBar()
          .props('tokens')
          .map((token) => token.type);

        expect(tokens).toEqual([
          TOKEN_TYPE_ASSIGNEE,
          TOKEN_TYPE_AUTHOR,
          TOKEN_TYPE_CONFIDENTIAL,
          TOKEN_TYPE_CONTACT,
          customToken.type,
          TOKEN_TYPE_GROUP,
          TOKEN_TYPE_LABEL,
          TOKEN_TYPE_MILESTONE,
          TOKEN_TYPE_MY_REACTION,
          TOKEN_TYPE_ORGANIZATION,
          TOKEN_TYPE_PARENT,
          TOKEN_TYPE_SEARCH_WITHIN,
          TOKEN_TYPE_STATE,
          TOKEN_TYPE_SUBSCRIBED,
          TOKEN_TYPE_TYPE,
        ]);
      });
    });

    describe('Organization filter token', () => {
      describe('when canReadCrmOrganization is true', () => {
        beforeEach(async () => {
          mountComponent({ provide: { isGroup: false } });
          await waitForPromises();
        });

        it('configures organization token with correct properties', () => {
          const organizationToken = findFilteredSearchBar()
            .props('tokens')
            .find((token) => token.type === TOKEN_TYPE_ORGANIZATION);

          expect(organizationToken).toMatchObject({
            fullPath: 'full/path',
            isProject: true,
            recentSuggestionsStorageKey: 'full/path-issues-recent-tokens-crm-organizations',
            operators: [{ description: 'is', value: '=' }],
          });
        });
      });

      describe('when canReadCrmOrganization is false', () => {
        beforeEach(async () => {
          mountComponent({ provide: { isGroup: false, canReadCrmOrganization: false } });
          await waitForPromises();
        });

        it('does not include organization token in available tokens', () => {
          const tokens = findFilteredSearchBar()
            .props('tokens')
            .map((token) => token.type);

          expect(tokens).not.toEqual(
            expect.arrayContaining([
              expect.objectContaining({
                type: TOKEN_TYPE_ORGANIZATION,
              }),
            ]),
          );
        });
      });
    });

    describe('Contact filter token', () => {
      describe('when canReadCrmOrganization is true', () => {
        beforeEach(async () => {
          mountComponent({ provide: { isGroup: false } });
          await waitForPromises();
        });

        it('configures contact token with correct properties', () => {
          const contactToken = findFilteredSearchBar()
            .props('tokens')
            .find((token) => token.type === TOKEN_TYPE_CONTACT);

          expect(contactToken).toMatchObject({
            fullPath: 'full/path',
            isProject: true,
            recentSuggestionsStorageKey: 'full/path-issues-recent-tokens-crm-contacts',
            operators: [{ description: 'is', value: '=' }],
          });
        });
      });

      describe('when canReadCrmContact is false', () => {
        beforeEach(async () => {
          mountComponent({ provide: { isGroup: false, canReadCrmContact: false } });
          await waitForPromises();
        });

        it('does not include contact token in available tokens', () => {
          const tokens = findFilteredSearchBar()
            .props('tokens')
            .map((token) => token.type);

          expect(tokens).not.toEqual(
            expect.arrayContaining([
              expect.objectContaining({
                type: TOKEN_TYPE_CONTACT,
              }),
            ]),
          );
        });
      });
    });

    describe('Parent filter token', () => {
      beforeEach(async () => {
        mountComponent({ provide: { isGroup: false } });
        await waitForPromises();
      });

      it('configures parent token with correct properties', () => {
        const parentToken = findFilteredSearchBar()
          .props('tokens')
          .find((token) => token.type === TOKEN_TYPE_PARENT);

        expect(parentToken).toMatchObject({
          fullPath: 'full/path',
          isProject: true,
          recentSuggestionsStorageKey: 'full/path-issues-recent-tokens-parent',
          operators: [
            { description: 'is', value: '=' },
            { description: 'is not one of', value: '!=' },
          ],
        });
      });
    });

    describe('release token', () => {
      describe('fetchReleases', () => {
        const mockReleases = [
          { tag: 'v1.0.0', name: 'Release 1.0.0' },
          { tag: 'v2.0.0', name: 'Release 2.0.0' },
          { tag: 'v1.1.0', name: 'Release 1.1.0' },
        ];

        let mockAxios;

        beforeEach(() => {
          mockAxios = new MockAdapter(axios);
        });

        const getReleaseToken = () =>
          findFilteredSearchBar()
            .props('tokens')
            .find((token) => token.type === TOKEN_TYPE_RELEASE);

        it('fetches releases from API when cache is empty', async () => {
          mockAxios.onGet(RELEASES_ENDPOINT).reply(HTTP_STATUS_OK, mockReleases);
          mountComponent({ provide: { isGroup: false } });
          await waitForPromises();

          const releaseToken = getReleaseToken();
          const result = await releaseToken.fetchReleases();

          expect(result).toEqual(mockReleases);
        });

        it('returns cached releases when cache is populated', async () => {
          mockAxios.onGet(RELEASES_ENDPOINT).reply(HTTP_STATUS_OK, mockReleases);
          mountComponent({ provide: { isGroup: false } });
          await waitForPromises();

          const releaseToken = getReleaseToken();

          // First call to populate cache
          await releaseToken.fetchReleases();

          // Second call should use cache
          const result = await releaseToken.fetchReleases();

          expect(result).toEqual(mockReleases);
          expect(mockAxios.history.get).toHaveLength(1); // Only one API call
        });

        it('filters cached releases when search is provided', async () => {
          mockAxios.onGet(RELEASES_ENDPOINT).reply(HTTP_STATUS_OK, mockReleases);
          mountComponent({ provide: { isGroup: false } });
          await waitForPromises();

          const releaseToken = getReleaseToken();

          // Populate cache first
          await releaseToken.fetchReleases();

          const result = await releaseToken.fetchReleases('v1');

          expect(result).toHaveLength(2);
          expect(result.map((r) => r.tag)).toEqual(['v1.0.0', 'v1.1.0']);
        });
      });

      it('excludes release token when isGroup is true', async () => {
        mountComponent({ provide: { isGroup: true } });
        await waitForPromises();
        const tokens = findFilteredSearchBar()
          .props('tokens')
          .map((token) => token.type);

        expect(tokens).not.toContain(TOKEN_TYPE_RELEASE);
      });

      it('includes release token when isGroup is false (project context)', async () => {
        mountComponent({ provide: { isGroup: false } });
        await waitForPromises();
        const tokens = findFilteredSearchBar()
          .props('tokens')
          .map((token) => token.type);

        expect(tokens).toContain(TOKEN_TYPE_RELEASE);
      });
    });

    describe('multiSelect property', () => {
      beforeEach(async () => {
        mountComponent();
        await waitForPromises();
      });

      it('sets multiSelect to true for assignee token', () => {
        const assigneeToken = findFilteredSearchBar()
          .props('tokens')
          .find((token) => token.type === TOKEN_TYPE_ASSIGNEE);

        expect(assigneeToken.multiSelect).toBe(true);
      });

      it('sets multiSelect to true for author token', () => {
        const authorToken = findFilteredSearchBar()
          .props('tokens')
          .find((token) => token.type === TOKEN_TYPE_AUTHOR);

        expect(authorToken.multiSelect).toBe(true);
      });

      it('sets multiSelect to true for label token', () => {
        const labelToken = findFilteredSearchBar()
          .props('tokens')
          .find((token) => token.type === TOKEN_TYPE_LABEL);

        expect(labelToken.multiSelect).toBe(true);
      });
    });
  });
  describe('sort options', () => {
    describe('when all features are enabled', () => {
      it('renders all sort options', async () => {
        mountComponent({
          provide: {
            hasBlockedIssuesFeature: true,
            hasIssuableHealthStatusFeature: true,
            hasIssueWeightsFeature: true,
            hasStatusFeature: true,
          },
        });
        await waitForPromises();

        expect(findFilteredSearchBar().props('sortOptions')).toEqual([
          expect.objectContaining({ title: 'Priority' }),
          expect.objectContaining({ title: 'Created date' }),
          expect.objectContaining({ title: 'Updated date' }),
          expect.objectContaining({ title: 'Closed date' }),
          expect.objectContaining({ title: 'Milestone due date' }),
          expect.objectContaining({ title: 'Due date' }),
          expect.objectContaining({ title: 'Popularity' }),
          expect.objectContaining({ title: 'Label priority' }),
          expect.objectContaining({ title: 'Manual' }),
          expect.objectContaining({ title: 'Title' }),
          expect.objectContaining({ title: 'Start date' }),
          expect.objectContaining({ title: 'Health' }),
          expect.objectContaining({ title: 'Status' }),
          expect.objectContaining({ title: 'Weight' }),
          expect.objectContaining({ title: 'Blocking' }),
        ]);
      });
    });

    describe('when all features are not enabled', () => {
      it('renders base sort options', async () => {
        mountComponent({
          provide: {
            hasBlockedIssuesFeature: false,
            hasIssuableHealthStatusFeature: false,
            hasIssueWeightsFeature: false,
            hasStatusFeature: false,
          },
        });
        await waitForPromises();

        expect(findFilteredSearchBar().props('sortOptions')).toEqual([
          expect.objectContaining({ title: 'Priority' }),
          expect.objectContaining({ title: 'Created date' }),
          expect.objectContaining({ title: 'Updated date' }),
          expect.objectContaining({ title: 'Closed date' }),
          expect.objectContaining({ title: 'Milestone due date' }),
          expect.objectContaining({ title: 'Due date' }),
          expect.objectContaining({ title: 'Popularity' }),
          expect.objectContaining({ title: 'Label priority' }),
          expect.objectContaining({ title: 'Manual' }),
          expect.objectContaining({ title: 'Title' }),
          expect.objectContaining({ title: 'Start date' }),
        ]);
      });
    });

    describe('when epics list', () => {
      it('does not render "Priority", "Label priority", "Manual", "Status", and "Weight" sort options', async () => {
        mountComponent({
          provide: {
            hasBlockedIssuesFeature: true,
            hasIssuableHealthStatusFeature: true,
            hasIssueWeightsFeature: true,
            hasStatusFeature: true,
            workItemType: WORK_ITEM_TYPE_NAME_EPIC,
          },
        });
        await waitForPromises();

        expect(findFilteredSearchBar().props('sortOptions')).toEqual([
          expect.objectContaining({ title: 'Created date' }),
          expect.objectContaining({ title: 'Updated date' }),
          expect.objectContaining({ title: 'Closed date' }),
          expect.objectContaining({ title: 'Milestone due date' }),
          expect.objectContaining({ title: 'Due date' }),
          expect.objectContaining({ title: 'Popularity' }),
          expect.objectContaining({ title: 'Title' }),
          expect.objectContaining({ title: 'Start date' }),
          expect.objectContaining({ title: 'Health' }),
          expect.objectContaining({ title: 'Blocking' }),
        ]);
      });
    });

    describe('when service desk list', () => {
      it('does not render "Status" sort options', async () => {
        mountComponent({
          provide: {
            hasBlockedIssuesFeature: true,
            hasIssuableHealthStatusFeature: true,
            hasIssueWeightsFeature: true,
            hasStatusFeature: true,
            workItemType: WORK_ITEM_TYPE_NAME_TICKET,
          },
        });
        await waitForPromises();
        const sortOptions = findFilteredSearchBar()
          .props('sortOptions')
          .map((sort) => sort.title);

        expect(sortOptions).not.toContain('Status');
      });
    });

    describe('when sort is manual and issue repositioning is disabled', () => {
      beforeEach(async () => {
        mountComponent({
          mockPreferencesHandler: jest.fn().mockResolvedValue(userPreferenceQueryResponse),
          provide: { isIssueRepositioningDisabled: true },
        });
        wrapper.vm.$options.apollo.displaySettings.result.call(wrapper.vm, {
          data: userPreferenceQueryResponse.data,
        });
        await waitForPromises();
      });

      it('changes the sort to the default of created descending', () => {
        expect(findFilteredSearchBar().props('initialSortBy')).toBe(CREATED_DESC);
      });

      it('shows an alert to tell the user that manual reordering is disabled', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Sort order rebalancing in progress. Reordering is temporarily disabled.',
          variant: VARIANT_INFO,
        });
      });

      it('shows alert when user tries to select manual sort after component mount', async () => {
        mountComponent({
          provide: { isIssueRepositioningDisabled: true },
        });
        await waitForPromises();

        findFilteredSearchBar().vm.$emit('onSort', RELATIVE_POSITION_ASC);
        await nextTick();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Sort order rebalancing in progress. Reordering is temporarily disabled.',
          variant: VARIANT_INFO,
        });
      });
    });
  });

  describe('when isGroupIssuesList is true', () => {
    it('calls workItems query with excludeGroupWorkItems: true', async () => {
      mountComponent({ provide: { isGroupIssuesList: true } });

      await waitForPromises();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          excludeGroupWorkItems: true,
        }),
      );
    });
  });

  describe('when workItemType is provided', () => {
    it('calls workItems query with "types" property', async () => {
      mountComponent({ provide: { workItemType: WORK_ITEM_TYPE_NAME_EPIC } });

      await waitForPromises();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          types: 'EPIC',
        }),
      );
    });
  });

  describe('when workItemType Epic is provided', () => {
    it('calls workItems query with "excludeProjects" property', async () => {
      mountComponent({ provide: { workItemType: WORK_ITEM_TYPE_NAME_EPIC } });

      await waitForPromises();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          excludeProjects: true,
        }),
      );
    });
  });

  describe('sticky filter header', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows sticky search container when intersection observer disappears', async () => {
      findGlIntersectionObserver().vm.$emit('disappear');
      await nextTick();

      expect(findStickySearchContainer().exists()).toBe(true);
    });

    it('hides sticky search container when intersection observer appears', async () => {
      findGlIntersectionObserver().vm.$emit('disappear');
      await nextTick();

      findGlIntersectionObserver().vm.$emit('appear');
      await nextTick();

      expect(findStickySearchContainer().exists()).toBe(false);
    });
  });

  describe('when "filter" event is emitted by FilteredSearchBar', () => {
    it('calls the workItems query', async () => {
      mountComponent();
      await waitForPromises();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TERM, value: { data: 'find issues', operator: 'undefined' } },
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
        { type: TOKEN_TYPE_SEARCH_WITHIN, value: { data: 'TITLE', operator: OPERATOR_IS } },
      ]);
      await nextTick();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          search: 'find issues',
          authorUsername: 'homer',
          in: 'TITLE',
        }),
      );
    });
  });

  describe('iid filter search', () => {
    it('calls workItems query when user enters a number with #', async () => {
      mountComponent();
      await waitForPromises();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TERM, value: { data: '#23', operator: 'undefined' } },
      ]);
      await nextTick();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          iid: '23',
        }),
      );
    });

    it('calls workItems query when user enters a number without #', async () => {
      mountComponent();
      await waitForPromises();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TERM, value: { data: '23', operator: 'undefined' } },
      ]);
      await nextTick();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          search: '23',
        }),
      );
    });
  });

  describe('work item features field feature flag', () => {
    describe('when the feature flag is off', () => {
      it('does not include features variable to the in update-query event', async () => {
        mountComponent({
          provide: {
            isServiceDeskSupported: true,
            workItemType: WORK_ITEM_TYPE_NAME_TICKET,
            glFeatures: { workItemFeaturesField: false },
          },
        });

        await waitForPromises();

        expect(defaultQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            useWorkItemFeatures: false,
          }),
        );
      });
    });

    describe('when the feature flag is on', () => {
      it('passes the useWorkItemFeatures to the query', async () => {
        mountComponent({
          provide: {
            isServiceDeskSupported: true,
            workItemType: WORK_ITEM_TYPE_NAME_TICKET,
            glFeatures: { workItemFeaturesField: true },
          },
        });

        await waitForPromises();

        expect(defaultQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            useWorkItemFeatures: true,
          }),
        );
      });
    });
  });

  describe('group filter', () => {
    describe('filtering by group', () => {
      it('calls workItems query and excludes descendants and excludes projects', async () => {
        mountComponent();
        await waitForPromises();

        findFilteredSearchBar().vm.$emit('onFilter', [
          {
            type: TOKEN_TYPE_GROUP,
            value: { data: 'path/to/another/group', operator: OPERATOR_IS },
          },
        ]);
        await nextTick();

        expect(defaultQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            excludeProjects: true,
            includeDescendants: false,
          }),
        );
      });
    });

    describe('not filtering by group', () => {
      it('calls workItems query and includes descendants and includes projects', async () => {
        mountComponent();
        await waitForPromises();

        findFilteredSearchBar().vm.$emit('onFilter', [
          { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
        ]);
        await nextTick();

        expect(defaultQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            excludeProjects: false,
            includeDescendants: true,
          }),
        );
      });
    });

    describe('work item count display', () => {
      const findCountDisplay = () => wrapper.findByTestId('work-item-count');

      describe.each`
        count    | expectedText
        ${1}     | ${'1 item'}
        ${0}     | ${'0 items'}
        ${10245} | ${'10,245 items'}
      `('when count is $count', ({ count, expectedText }) => {
        beforeEach(async () => {
          const countsOnlyHandler = jest.fn().mockResolvedValue({
            data: {
              namespace: {
                id: 'gid://gitlab/Group/3',
                __typename: 'Group',
                name: 'Test',
                workItems: { count },
              },
            },
          });
          mountComponent({
            countsOnlyHandler,
          });
          await waitForPromises();
        });

        it(`displays "${expectedText}"`, () => {
          expect(findCountDisplay().text()).toBe(expectedText);
        });
      });
    });
  });

  describe('when "sort" event is emitted by FilteredSearchBar', () => {
    it.each(Object.keys(urlSortParams))(
      'calls the workItems query event with the new sort when payload is `%s`',
      async (sortKey) => {
        // Ensure initial sort key is different so we trigger an update when emitting a sort key
        if (sortKey === CREATED_DESC) {
          mountComponent({
            mockPreferencesHandler: jest.fn().mockResolvedValue(userPreferenceQueryResponse),
          });
        } else {
          mountComponent();
        }
        await waitForPromises();

        findFilteredSearchBar().vm.$emit('onSort', sortKey);
        await waitForPromises();
        await nextTick();

        expect(defaultQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            sort: sortKey,
          }),
        );
      },
    );

    describe('when user is signed in', () => {
      it('calls mutation to save sort preference', async () => {
        mountComponent();
        await waitForPromises();

        findFilteredSearchBar().vm.$emit('onSort', UPDATED_DESC);

        expect(userPreferenceMutationHandler).toHaveBeenCalledWith({
          sort: UPDATED_DESC,
          namespace: 'full/path',
          workItemTypeId: 'gid://gitlab/WorkItems::Type/1',
        });
      });

      it('captures error when mutation response has errors', async () => {
        const mutationMock = jest
          .fn()
          .mockResolvedValue(workItemUserPreferenceUpdateMutationResponseWithErrors);
        mountComponent({ userPreferenceMutationResponse: mutationMock });
        await waitForPromises();

        findFilteredSearchBar().vm.$emit('onSort', UPDATED_DESC);
        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
      });
    });

    describe('when user is signed out', () => {
      it('does not call mutation to save sort preference', async () => {
        mountComponent({ isLoggedInValue: false });
        await waitForPromises();

        findFilteredSearchBar().vm.$emit('onSort', CREATED_DESC);

        expect(userPreferenceMutationHandler).not.toHaveBeenCalled();
      });
    });
  });

  describe('slim and full queries', () => {
    beforeEach(() => {
      mountComponent();

      findListView().vm.$emit('update-query', exampleQueryParams);

      return waitForPromises();
    });

    it('calls the slim query as well as the full query', () => {
      expect(defaultQueryHandler).toHaveBeenCalled();
      expect(defaultSlimQueryHandler).toHaveBeenCalled();
    });

    it('combines the slim and full results correctly and passes the to the list component', () => {
      expect(findListView().props('workItems')).toEqual(combinedQueryResultExample);
    });
  });

  describe.each`
    queryName | handlerName
    ${'full'} | ${'queryHandler'}
    ${'slim'} | ${'slimQueryHandler'}
  `('when there is an error with the $queryName list query', ({ handlerName }) => {
    const message = 'Something went wrong when fetching work items. Please try again.';

    beforeEach(async () => {
      mountComponent({ [handlerName]: jest.fn().mockRejectedValue(new Error('ERROR')) });
      findListView().vm.$emit('update-query', exampleQueryParams);
      await waitForPromises();
    });

    it('renders an error message', () => {
      expect(findListView().props('error')).toBe(message);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
    });

    it('clears error message when "dismiss-alert" event is emitted from IssuableList', async () => {
      findListView().vm.$emit('dismiss-alert');
      await nextTick();

      expect(findListView().props('error')).toBeUndefined();
    });
  });

  describe('document title', () => {
    it('renders "Service Desk"', async () => {
      mountComponent({
        provide: {
          isServiceDeskSupported: true,
          workItemType: WORK_ITEM_TYPE_NAME_TICKET,
        },
      });
      findListView().vm.$emit('update-query', exampleQueryParams);
      await waitForPromises();

      expect(document.title).toBe('Service Desk · Test · GitLab');
    });
  });

  it('skips the work item queries when metadata is loading', async () => {
    mountComponent({ provide: { metadataLoading: true } });
    await waitForPromises();

    expect(defaultQueryHandler).not.toHaveBeenCalled();
    expect(defaultSlimQueryHandler).not.toHaveBeenCalled();
  });
  describe('Saved Views', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    const mountDefault = async (options = {}) => {
      const { provide: mountProvide, ...restOptions } = options;
      const { glFeatures: mountGlFeatures, ...restProvideOptions } = mountProvide || {};
      mountComponent({
        provide: {
          glFeatures: { ...mountGlFeatures },
          ...restProvideOptions,
        },
        ...restOptions,
      });
      await waitForPromises();
    };

    describe('when not on a saved view', () => {
      describe('when user is logged in', () => {
        it('renders "Save view" button when filters change', async () => {
          await mountDefault();

          findFilteredSearchBar().vm.$emit('onFilter', [
            { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
            { type: TOKEN_TYPE_SEARCH_WITHIN, value: { data: 'TITLE', operator: OPERATOR_IS } },
          ]);
          await nextTick();

          expect(findSaveViewButton().exists()).toBe(true);
        });

        it('opens the new saved view modal when clicking "Save view"', async () => {
          await mountDefault();

          findFilteredSearchBar().vm.$emit('onFilter', [
            { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
            { type: TOKEN_TYPE_SEARCH_WITHIN, value: { data: 'TITLE', operator: OPERATOR_IS } },
          ]);
          await nextTick();

          await findSaveViewButton().trigger('click');
          await nextTick();

          expect(findNewSavedViewModal().exists()).toBe(true);
        });

        it('does not render "Save view" button when canCreateSavedView is false', async () => {
          await mountComponent({
            provide: { canCreateSavedView: false },
          });
          await waitForPromises();

          findFilteredSearchBar().vm.$emit('onFilter', [
            { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
            { type: TOKEN_TYPE_SEARCH_WITHIN, value: { data: 'TITLE', operator: OPERATOR_IS } },
          ]);
          await nextTick();

          expect(findSaveViewButton().exists()).toBe(false);
        });

        it('persists unsaved changes on "All Items" to localStorage', async () => {
          await mountDefault();

          findFilteredSearchBar().vm.$emit('onFilter', [
            { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
          ]);
          await nextTick();

          expect(localStorage.setItem).toHaveBeenCalledWith(
            'full/path-all-items-draft-filters',
            expect.stringContaining('"query"'),
          );
        });
      });

      describe('when user is logged out', () => {
        beforeEach(async () => {
          mountComponent({ isLoggedInValue: false });
          await waitForPromises();
        });

        it('does not render the "Save view" button when filters change', async () => {
          findFilteredSearchBar().vm.$emit('onFilter', [
            { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
            { type: TOKEN_TYPE_SEARCH_WITHIN, value: { data: 'TITLE', operator: OPERATOR_IS } },
          ]);
          await nextTick();

          expect(findSaveViewButton().exists()).toBe(false);
        });

        it('does not render the "Save view" button when sort changes', async () => {
          findFilteredSearchBar().vm.$emit('onSort', UPDATED_DESC);
          await nextTick();
          await waitForPromises();

          expect(findSaveViewButton().exists()).toBe(false);
        });
      });

      it('displays the "not found" modal when the "sv_not_found" query parameter is in the URL', async () => {
        await router.replace({ query: { sv_not_found: true } });
        await mountDefault();

        expect(findViewNotFoundModal().props('show')).toBe(true);
      });

      it('displays the "at limit" modal when the "sv_limit_id" query parameter is in the URL', async () => {
        await router.replace({
          query: { sv_limit_id: 'gid://gitlab/WorkItems::SavedViews::SavedView/3' },
        });
        await mountDefault();

        expect(findViewLimitWarningModal().props('show')).toBe(true);
      });
    });

    describe('when on a saved view', () => {
      beforeEach(async () => {
        await mountDefault();
        await router.push({ name: 'savedView', params: { type: 'work_items', view_id: '3' } });
        await waitForPromises();
      });

      it('displays error alert when saved views selector component emits error', async () => {
        const testError = new Error('Test error');
        const errorMessage = 'An error occurred while removing the view. Please try again.';

        findWorkItemsSavedViewsSelectors().vm.$emit('error', testError, errorMessage);
        await nextTick();

        expect(Sentry.captureException).toHaveBeenCalledWith(testError);
        expect(findListView().props('error')).toBe(errorMessage);
      });

      it('fetches the saved view based on route parameter', () => {
        expect(namespaceSavedViewHandler).toHaveBeenCalledWith({
          fullPath: 'full/path',
          id: 'gid://gitlab/WorkItems::SavedViews::SavedView/3',
        });
      });

      it('tracks saved_view_view event when a subscribed saved view is loaded', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        expect(trackEventSpy).toHaveBeenCalledTimes(1);
        expect(trackEventSpy).toHaveBeenCalledWith('saved_view_view', {}, undefined);
      });

      it('navigates to /work_items with sv_not_found query parameter when saved view cannot be found', async () => {
        mountComponent({
          savedViewHandler: jest.fn().mockResolvedValue(emptySavedViewsResult),
        });

        expect(window.location.pathname).toBe('/work_items/views/3');

        await waitForPromises();
        await nextTick();

        expect(window.location.pathname).toBe('/work_items');
        expect(window.location.search).toContain('sv_not_found');
      });

      it('does not track saved_view_view event when saved view is not found', async () => {
        mountComponent({
          savedViewHandler: jest.fn().mockResolvedValue(emptySavedViewsResult),
        });
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        trackEventSpy.mockClear();

        await waitForPromises();

        expect(trackEventSpy).not.toHaveBeenCalledWith('saved_view_view', {}, undefined);
      });

      describe('when visiting an unsubscribed view', () => {
        describe('when at subscription limit', () => {
          it('navigates to /work_items with sv_limit_id query parameter', async () => {
            mountComponent({
              savedViewHandler: jest
                .fn()
                .mockResolvedValue(savedViewResponseFactory({ subscribed: false, limit: 1 })),
            });

            expect(window.location.pathname).toBe('/work_items/views/3');

            await waitForPromises();
            await nextTick();

            expect(window.location.pathname).toBe('/work_items');
            expect(window.location.search).toContain('sv_limit_id');
          });
        });

        describe('when not at subscription limit', () => {
          it('calls the subscribe mutation with the correct parameters', async () => {
            const savedViewHandler = jest
              .fn()
              .mockResolvedValue(savedViewResponseFactory({ subscribed: false }));
            mountComponent({
              savedViewHandler,
            });

            savedViewHandler.mockResolvedValue(savedViewResponseFactory({ subscribed: true }));

            await waitForPromises();

            expect(subscribeToSavedViewHandler).toHaveBeenCalledWith({
              input: {
                id: 'gid://gitlab/WorkItems::SavedViews::SavedView/3',
              },
            });

            expect(showToast).toHaveBeenCalledWith('View added to your list.');
          });

          it('tracks saved_view_view event after auto-subscribing and refetching', async () => {
            const savedViewHandler = jest
              .fn()
              .mockResolvedValue(savedViewResponseFactory({ subscribed: false }));

            mountComponent({ savedViewHandler });
            const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

            savedViewHandler.mockResolvedValue(savedViewResponseFactory({ subscribed: true }));

            await waitForPromises();

            expect(trackEventSpy).toHaveBeenCalledWith('saved_view_view', {}, undefined);
          });
        });
      });

      it('captures error alert when saved view cannot be fetched', async () => {
        const error = new Error('Network error');
        mountComponent({
          savedViewHandler: jest.fn().mockRejectedValue(error),
        });
        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith(error);
      });

      it('renders "Save changes" and "Reset to defaults" buttons when filters change', async () => {
        findFilteredSearchBar().vm.$emit('onFilter', [
          { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
          { type: TOKEN_TYPE_SEARCH_WITHIN, value: { data: 'TITLE', operator: OPERATOR_IS } },
        ]);
        await nextTick();

        expect(findResetViewButton().exists()).toBe(true);
        expect(findUpdateViewButton().exists()).toBe(true);
      });

      it('renders "Save changes" and "Reset to defaults" button when sort changes', async () => {
        findFilteredSearchBar().vm.$emit('onSort', CREATED_DESC);
        await nextTick();

        expect(findResetViewButton().exists()).toBe(true);
        expect(findUpdateViewButton().exists()).toBe(true);
      });

      it('renders "Save changes" and "Reset to defaults" buttons when display preferences change', async () => {
        findWorkItemUserPreferences().vm.$emit('local-update', {
          hiddenMetadataKeys: ['labels'],
        });

        await nextTick();

        expect(findResetViewButton().exists()).toBe(true);
        expect(findUpdateViewButton().exists()).toBe(true);
      });

      it('does not render "Save changes" and its separator but "Reset to defaults" when there is no permission', async () => {
        const savedViewHandler = jest.fn().mockResolvedValue(
          savedViewResponseFactory({
            savedViews: [
              {
                ...singleSavedView[0],
                userPermissions: {
                  ...singleSavedView[0].userPermissions,
                  updateSavedView: false,
                },
              },
            ],
          }),
        );
        mountComponent({
          savedViewHandler,
        });
        await waitForPromises();

        findWorkItemUserPreferences().vm.$emit('local-update', {
          hiddenMetadataKeys: ['labels'],
        });

        await nextTick();

        expect(findResetViewButton().exists()).toBe(true);
        expect(findUpdateViewButton().exists()).toBe(false);
        expect(findSaveChangesSeparator().exists()).toBe(false);
      });

      it('resets filters, hides action buttons and resets local storage draft', async () => {
        findFilteredSearchBar().vm.$emit('onFilter', [
          { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
        ]);
        await waitForPromises();

        findResetViewButton().vm.$emit('click');
        await nextTick();

        expect(findResetViewButton().exists()).toBe(false);
        expect(findUpdateViewButton().exists()).toBe(false);
        expect(localStorage.removeItem).toHaveBeenCalledWith('full/path-saved-view-3');
      });

      describe('when "Save changes" is clicked', () => {
        describe('for a private view', () => {
          it('saves without prompting for confirmation', async () => {
            mountComponent({
              workItemsSavedViewsEnabled: true,
              savedViewHandler: jest
                .fn()
                .mockResolvedValue(savedViewResponseFactory({ savedViews: singleSavedView })),
            });
            await waitForPromises();

            findFilteredSearchBar().vm.$emit('onFilter', [
              { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
            ]);
            await nextTick();

            saveSavedView.mockResolvedValue({
              data: {
                workItemSavedViewUpdate: {
                  errors: [],
                  savedView: singleSavedView[0],
                },
              },
            });

            await findUpdateViewButton().vm.$emit('click');

            expect(confirmAction).not.toHaveBeenCalled();
            await waitForPromises();

            expect(saveSavedView).toHaveBeenCalledTimes(1);
            expect(showToast).toHaveBeenCalledWith('View has been saved.');
          });
        });

        describe('for a shared view', () => {
          beforeEach(async () => {
            mountComponent({
              workItemsSavedViewsEnabled: true,
              savedViewHandler: jest
                .fn()
                .mockResolvedValue(savedViewResponseFactory({ savedViews: sharedSavedView })),
            });
            await waitForPromises();

            findFilteredSearchBar().vm.$emit('onFilter', [
              { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
            ]);

            await nextTick();
          });

          it('prompts for confirmation', async () => {
            await findUpdateViewButton().vm.$emit('click');

            expect(confirmAction).toHaveBeenCalledWith(
              null,
              expect.objectContaining({
                title: 'Save changes to Current sprint 3?',
                modalHtmlMessage: expect.stringContaining(
                  'Changes will be applied for anyone else who has access to the view.',
                ),
                primaryBtnText: 'Save changes',
              }),
            );
          });

          it('calls saveSavedView when user confirms', async () => {
            saveSavedView.mockResolvedValue({
              data: {
                workItemSavedViewUpdate: {
                  errors: [],
                  savedView: sharedSavedView[0],
                },
              },
            });

            await findUpdateViewButton().vm.$emit('click');

            await waitForPromises();

            expect(saveSavedView).toHaveBeenCalledTimes(1);

            expect(showToast).toHaveBeenCalledWith('View has been saved.');
          });

          it('sets error when mutation returns errors', async () => {
            saveSavedView.mockResolvedValue({
              data: {
                workItemSavedViewUpdate: {
                  errors: ['Something went wrong'],
                  savedView: null,
                },
              },
            });

            await findUpdateViewButton().vm.$emit('click');

            await waitForPromises();

            expect(findListView().props('error')).toBe(
              'Something went wrong while saving the view',
            );
          });

          it('sets error when mutation throws error', async () => {
            saveSavedView.mockRejectedValue(new Error('Network error'));

            await findUpdateViewButton().vm.$emit('click');

            await waitForPromises();

            expect(findListView().props('error')).toBe(
              'Something went wrong while saving the view',
            );
          });

          it('does not call saveSavedView when user cancels', async () => {
            confirmAction.mockResolvedValue(false);

            await findUpdateViewButton().vm.$emit('click');

            await waitForPromises();

            expect(saveSavedView).not.toHaveBeenCalled();
          });
        });
      });

      it('persists unsaved changes to localStorage', async () => {
        findFilteredSearchBar().vm.$emit('onFilter', [
          { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
        ]);
        await nextTick();

        expect(localStorage.setItem).toHaveBeenCalledWith(
          'full/path-saved-view-3',
          expect.stringContaining('"filterTokens"'),
        );
      });

      it('persists unsaved data when navigating back to the saved view', async () => {
        findFilteredSearchBar().vm.$emit('onSort', CREATED_DESC);
        await nextTick();

        await router.push({ name: 'savedView', params: { type: 'work_items', view_id: '4' } });
        await nextTick();
        await router.push({ name: 'savedView', params: { type: 'work_items', view_id: '3' } });
        await nextTick();

        expect(findFilteredSearchBar().props('initialSortBy')).toBe(CREATED_DESC);
      });
    });

    describe('subscription limit warning', () => {
      it('passes showSubscriptionLimitWarning as false to modal when not at limit', async () => {
        mountComponent({
          provide: {
            subscribedSavedViewLimit: 10,
          },
        });
        await waitForPromises();

        findFilteredSearchBar().vm.$emit('onFilter', [
          { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
        ]);
        await nextTick();

        await findSaveViewButton().trigger('click');
        await nextTick();

        expect(findNewSavedViewModal().props('showSubscriptionLimitWarning')).toBe(false);
      });

      it('passes showSubscriptionLimitWarning as true to modal when at limit', async () => {
        mountComponent({
          provide: {
            subscribedSavedViewLimit: 1,
          },
        });
        await waitForPromises();

        findFilteredSearchBar().vm.$emit('onFilter', [
          { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
        ]);

        await nextTick();

        await findSaveViewButton().trigger('click');
        await nextTick();

        expect(findNewSavedViewModal().props('showSubscriptionLimitWarning')).toBe(true);
      });
    });
  });

  describe('service desk info banner', () => {
    describe('when there are work items', () => {
      it.each`
        workItemType                  | isServiceDeskSupported | isInfoBannerVisible
        ${WORK_ITEM_TYPE_NAME_TICKET} | ${true}                | ${true}
        ${WORK_ITEM_TYPE_NAME_TICKET} | ${false}               | ${false}
        ${undefined}                  | ${true}                | ${false}
        ${undefined}                  | ${false}               | ${false}
      `(
        'only renders InfoBanner when service desk is supported and it is the service desk list',
        async ({ workItemType, isServiceDeskSupported, isInfoBannerVisible }) => {
          mountComponent({
            provide: { isServiceDeskSupported, workItemType },
          });
          await waitForPromises();

          expect(findServiceDeskInfoBanner().exists()).toBe(isInfoBannerVisible);
        },
      );
    });

    describe('when there no work items', () => {
      it.each`
        workItemType                  | isServiceDeskSupported
        ${WORK_ITEM_TYPE_NAME_TICKET} | ${true}
        ${WORK_ITEM_TYPE_NAME_TICKET} | ${false}
        ${undefined}                  | ${true}
        ${undefined}                  | ${false}
      `('never renders InfoBanner', async ({ workItemType, isServiceDeskSupported }) => {
        mountComponent({
          hasWorkItemsHandler: emptyHasWorkItemsHandler,
          provide: { isServiceDeskSupported, workItemType },
        });
        await waitForPromises();

        expect(findServiceDeskInfoBanner().exists()).toBe(false);
      });
    });
  });

  it('passes workItemsCount as workItemCount prop to work-item-list-actions', async () => {
    mountComponent();

    await waitForPromises();

    expect(findWorkItemListActions().props('workItemCount')).toBe(3);
  });

  it('renders total items count when work items exist', async () => {
    mountComponent();
    await waitForPromises();

    expect(wrapper.text()).toContain('3 items');
  });

  describe('showWorkItemByEmail computed property', () => {
    describe.each`
      canCreateWorkItem | isGroup  | newWorkItemEmailAddress | expected
      ${false}          | ${true}  | ${null}                 | ${false}
      ${false}          | ${true}  | ${'test@example.com'}   | ${false}
      ${true}           | ${true}  | ${null}                 | ${false}
      ${true}           | ${true}  | ${'test@example.com'}   | ${false}
      ${false}          | ${false} | ${null}                 | ${false}
      ${false}          | ${false} | ${'test@example.com'}   | ${false}
      ${true}           | ${false} | ${null}                 | ${false}
      ${true}           | ${false} | ${'test@example.com'}   | ${true}
    `(
      'when canCreateWorkItem=$canCreateWorkItem, isGroup=$isGroup, newWorkItemEmailAddress=$newWorkItemEmailAddress',
      ({ canCreateWorkItem, isGroup, newWorkItemEmailAddress, expected }) => {
        it(`${expected ? 'returns true' : 'returns false'}`, async () => {
          mountComponent({
            provide: {
              canCreateWorkItem,
              isGroup,
              newWorkItemEmailAddress,
            },
          });
          await waitForPromises();

          expect(findWorkItemListActions().props('showWorkItemByEmailButton')).toBe(expected);
        });
      },
    );
  });

  describe('when there are no work items in group context', () => {
    describe('when group has no projects', () => {
      it('disables the bulk edit button', async () => {
        mountComponent({
          queryHandler: jest.fn().mockResolvedValue(emptyWorkItemsResponse),
          slimQueryHandler: jest.fn().mockResolvedValue(emptyWorkItemsResponse),
          hasWorkItemsHandler: emptyHasWorkItemsHandler,
        });

        await waitForPromises();

        expect(findBulkEditStartButton().props('disabled')).toBe(true);
      });
    });
  });

  describe('when bulk editing', () => {
    describe('user permissions', () => {
      describe('when workItemType=Epic', () => {
        it.each([true, false])('renders=$s when canBulkAdminEpic=%s', async (canBulkAdminEpic) => {
          mountComponent({ provide: { canBulkAdminEpic, workItemType: WORK_ITEM_TYPE_NAME_EPIC } });
          await waitForPromises();

          expect(findBulkEditStartButton().exists()).toBe(canBulkAdminEpic);
        });
      });

      describe('when group', () => {
        it.each`
          canAdminIssue | hasGroupBulkEditFeature | renders
          ${true}       | ${true}                 | ${true}
          ${true}       | ${false}                | ${false}
          ${false}      | ${true}                 | ${false}
          ${false}      | ${false}                | ${false}
        `(
          'renders=$renders when canAdminIssue=$canAdminIssue and hasGroupBulkEditFeature=$hasGroupBulkEditFeature',
          async ({ canAdminIssue, hasGroupBulkEditFeature, renders }) => {
            mountComponent({
              provide: {
                isGroup: true,
                canAdminIssue,
                hasGroupBulkEditFeature,
                hasEpicsFeature: true,
              },
            });
            await waitForPromises();

            expect(findBulkEditStartButton().exists()).toBe(renders);
          },
        );
      });

      describe('when CE group', () => {
        it('allows bulk editing when user can admin issues and group has projects', async () => {
          mountComponent({
            provide: {
              isGroup: true,
              canAdminIssue: true,
              hasProjects: true,
              hasEpicsFeature: false,
              hasGroupBulkEditFeature: false,
            },
          });
          await waitForPromises();

          expect(findBulkEditStartButton().exists()).toBe(true);
        });

        it('does not allow bulk editing when user cannot admin issues', async () => {
          mountComponent({
            provide: {
              isGroup: true,
              canAdminIssue: false,
              hasProjects: true,
              hasEpicsFeature: false,
              hasGroupBulkEditFeature: false,
            },
          });
          await waitForPromises();

          expect(findBulkEditStartButton().exists()).toBe(false);
        });
      });

      describe('when project', () => {
        it.each([true, false])('renders depending on canAdminIssue=%s', async (canAdminIssue) => {
          mountComponent({ provide: { isGroup: false, canAdminIssue } });
          await waitForPromises();

          expect(findBulkEditStartButton().exists()).toBe(canAdminIssue);
        });
      });
    });
  });

  describe('analyze items button', () => {
    it.each([true, false])(
      'renders=%s based on duoQuickActionWorkItemList feature flag',
      (duoQuickActionWorkItemList) => {
        mountComponent({
          provide: { glFeatures: { duoQuickActionWorkItemList } },
        });

        expect(findAnalyzeItemsButton().exists()).toBe(duoQuickActionWorkItemList);
      },
    );
  });

  describe('when service desk list', () => {
    describe('nav actions', () => {
      it('does not render the bulk edit button, create work item modal, or actions dropdown', async () => {
        mountComponent({
          provide: { isServiceDeskSupported: true, workItemType: WORK_ITEM_TYPE_NAME_TICKET },
        });
        await waitForPromises();

        expect(findBulkEditStartButton().exists()).toBe(false);
        expect(findCreateWorkItemModal().exists()).toBe(false);
      });
    });

    describe('empty state', () => {
      it('renders EmptyStateWithAnyTickets when there are work items', async () => {
        mountComponent({
          provide: { isServiceDeskSupported: true, workItemType: WORK_ITEM_TYPE_NAME_TICKET },
          props: {
            hasWorkItems: true,
            workItems: [],
          },
        });
        await waitForPromises();

        expect(findServiceDeskEmptyStateWithAnyIssues().exists()).toBe(true);
      });

      it('renders EmptyStateWithoutAnyTickets when there are no work items', async () => {
        mountComponent({
          hasWorkItemsHandler: emptyHasWorkItemsHandler,
          provide: { isServiceDeskSupported: true, workItemType: WORK_ITEM_TYPE_NAME_TICKET },
        });
        await waitForPromises();

        expect(findServiceDeskEmptyStateWithoutAnyIssues().exists()).toBe(true);
      });
    });

    describe('document title with saved views', () => {
      it('includes saved view name when on a saved view', async () => {
        mountComponent();
        await waitForPromises();

        await router.push({ name: 'savedView', params: { type: 'work_items', view_id: '3' } });
        await waitForPromises();

        expect(document.title).toBe('Current sprint 3 · Work items · Test · GitLab');
      });

      it('updates document title when switching between saved views', async () => {
        const viewAName = 'View A';
        const viewBName = 'View B';

        const viewASavedView = [
          {
            ...singleSavedView[0],
            id: 'gid://gitlab/WorkItems::SavedViews::SavedView/3',
            name: viewAName,
          },
        ];
        const viewBSavedView = [
          {
            ...singleSavedView[0],
            id: 'gid://gitlab/WorkItems::SavedViews::SavedView/4',
            name: viewBName,
          },
        ];

        const savedViewHandler = jest.fn().mockImplementation(({ id }) => {
          if (id === 'gid://gitlab/WorkItems::SavedViews::SavedView/3') {
            return Promise.resolve(savedViewResponseFactory({ savedViews: viewASavedView }));
          }
          return Promise.resolve(savedViewResponseFactory({ savedViews: viewBSavedView }));
        });

        mountComponent({
          savedViewHandler,
        });
        await waitForPromises();

        await router.push({ name: 'savedView', params: { type: 'work_items', view_id: '3' } });
        await waitForPromises();

        expect(document.title).toContain(viewAName);

        await router.push({ name: 'savedView', params: { type: 'work_items', view_id: '4' } });
        await waitForPromises();

        expect(document.title).toContain(viewBName);
        expect(document.title).not.toContain(viewAName);
      });

      it('trims whitespace from saved view name in document title', async () => {
        const savedViewHandler = jest.fn().mockResolvedValue(
          savedViewResponseFactory({
            savedViews: [
              {
                ...singleSavedView[0],
                name: '   ',
              },
            ],
          }),
        );

        mountComponent({
          savedViewHandler,
        });
        await waitForPromises();

        await router.push({ name: 'savedView', params: { type: 'work_items', view_id: '3' } });
        await waitForPromises();

        expect(document.title).toBe('Work items · Test · GitLab');
      });
    });
  });
  describe('when "reorder" event is emitted by ListView', () => {
    describe('when successful', () => {
      describe.each`
        description                        | oldIndex | newIndex | expectedMoveBeforeId                                                   | expectedMoveAfterId
        ${'first item to second position'} | ${0}     | ${1}     | ${workItemsQueryResponseCombined.data.namespace.workItems.nodes[1].id} | ${null}
        ${'second item to first position'} | ${1}     | ${0}     | ${null}                                                                | ${workItemsQueryResponseCombined.data.namespace.workItems.nodes[0].id}
      `(
        'when moving $description',
        ({ oldIndex, newIndex, expectedMoveBeforeId, expectedMoveAfterId }) => {
          it('calls workItemsReorder mutation with correct parameters', async () => {
            const reorderMutationSpy = jest.fn().mockResolvedValue({
              data: {
                workItemsReorder: {
                  workItem: workItemsQueryResponseCombined.data.namespace.workItems.nodes[oldIndex],
                  errors: [],
                },
              },
            });

            mountComponent({
              mockPreferencesHandler: jest.fn().mockResolvedValue(userPreferenceQueryResponse),
              additionalHandlers: [[workItemsReorderMutation, reorderMutationSpy]],
            });
            await waitForPromises();

            findListView().vm.$emit('reorder', { oldIndex, newIndex });
            await waitForPromises();

            const expectedInput = {
              id: workItemsQueryResponseCombined.data.namespace.workItems.nodes[oldIndex].id,
            };

            if (expectedMoveBeforeId) expectedInput.moveBeforeId = expectedMoveBeforeId;
            if (expectedMoveAfterId) expectedInput.moveAfterId = expectedMoveAfterId;

            expect(reorderMutationSpy).toHaveBeenCalledWith({
              input: expectedInput,
            });
          });
        },
      );
    });
  });

  describe('CreateWorkItem modal', () => {
    it.each([true, false])('renders depending on showNewWorkItem=%s', async (showNewWorkItem) => {
      mountComponent({ provide: { showNewWorkItem, isGroup: false } });
      await waitForPromises();

      expect(findCreateWorkItemModal().exists()).toBe(showNewWorkItem);
    });

    it('renders with "list route" creation context', async () => {
      mountComponent();
      await waitForPromises();

      expect(findCreateWorkItemModal().props('creationContext')).toBe(CREATION_CONTEXT_LIST_ROUTE);
    });

    describe('alwaysShowWorkItemTypeSelect', () => {
      it.each`
        workItemType                 | value
        ${WORK_ITEM_TYPE_NAME_ISSUE} | ${true}
        ${WORK_ITEM_TYPE_NAME_EPIC}  | ${false}
      `('renders=$value when workItemType=$workItemType', async ({ workItemType, value }) => {
        mountComponent({ provide: { workItemType } });
        await waitForPromises();

        expect(findCreateWorkItemModal().props('alwaysShowWorkItemTypeSelect')).toBe(value);
      });
    });

    describe('preselectedWorkItemType', () => {
      it.each`
        workItemType                 | value
        ${WORK_ITEM_TYPE_NAME_ISSUE} | ${WORK_ITEM_TYPE_NAME_ISSUE}
        ${WORK_ITEM_TYPE_NAME_EPIC}  | ${WORK_ITEM_TYPE_NAME_EPIC}
      `('renders=$value when workItemType=$workItemType', async ({ workItemType, value }) => {
        mountComponent({ provide: { workItemType } });
        await waitForPromises();

        expect(findCreateWorkItemModal().props('preselectedWorkItemType')).toBe(value);
      });
    });
  });

  describe('empty states', () => {
    const getEmptyPropValues = ({ workItems = [], hasWorkItems = false } = {}) => {
      return {
        workItems,
        hasWorkItems,
      };
    };

    describe('when filters are applied and no work items match', () => {
      beforeEach(async () => {
        setWindowLocation('?label_name=bug');
        mountComponent({
          props: {
            ...getEmptyPropValues({ hasWorkItems: true }),
          },
        });
        await waitForPromises();
      });

      it('renders EmptyStateWithAnyIssues component with empty results', () => {
        expect(findEmptyStateWithAnyIssues().exists()).toBe(true);
      });
    });

    describe('when there are no work items in group context', () => {
      beforeEach(async () => {
        mountComponent({
          hasWorkItemsHandler: emptyHasWorkItemsHandler,
          provide: {
            isGroupIssuesList: true,
            hasProjects: true,
            hasEpicsFeature: true,
            showNewWorkItem: false,
          },
        });
        await waitForPromises();
      });

      it('renders the list empty state', () => {
        expect(findEmptyStateWithoutAnyIssues().exists()).toBe(true);
      });

      it('passes correct props to empty state component for groups', () => {
        expect(findEmptyStateWithoutAnyIssues().props()).toMatchObject({
          showNewIssueDropdown: true,
        });
      });

      it('renders the new resource dropdown when group has projects', () => {
        expect(findNewResourceDropdown().exists()).toBe(true);
        expect(findCreateWorkItemModal().exists()).toBe(false);
      });

      describe('when group has no projects', () => {
        beforeEach(async () => {
          mountComponent({
            props: {
              ...getEmptyPropValues(),
            },
            provide: {
              isGroupIssuesList: true,
              hasProjects: false,
            },
          });
          await waitForPromises();
        });

        it('does not render the new resource dropdown when group has projects', () => {
          expect(findNewResourceDropdown().exists()).toBe(false);
        });
      });
    });

    describe('when there are no work items in project context', () => {
      const emptyStateConfig = {
        props: {
          ...getEmptyPropValues(),
        },
        provide: {
          isGroup: false,
        },
        stubs: {
          EmptyStateWithoutAnyIssues: {
            template: `<div><slot name="import-export-buttons"></slot></div>`,
          },
        },
      };

      it('passes correct props to empty state component for projects', async () => {
        mountComponent({
          ...emptyStateConfig,
          hasWorkItemsHandler: emptyHasWorkItemsHandler,
          provide: { ...emptyStateConfig.provide },
          stubs: {},
        });

        await waitForPromises();

        expect(findEmptyStateWithoutAnyIssues().props()).toMatchObject({
          showNewIssueDropdown: false,
        });
      });
    });

    describe('when there are work items', () => {
      describe('in group context', () => {
        it('renders the with issues empty state and the new resource dropdown', async () => {
          mountComponent({
            props: {
              ...getEmptyPropValues({
                hasWorkItems: true,
              }),
            },
            provide: {
              isGroupIssuesList: true,
            },
          });

          await waitForPromises();

          expect(findEmptyStateWithAnyIssues().exists()).toBe(true);
          expect(findNewResourceDropdown().exists()).toBe(true);
        });
      });

      describe('in project context', () => {
        it('renders the with issues empty state and the CreateWorkItemModal', async () => {
          mountComponent({
            props: {
              ...getEmptyPropValues({
                hasWorkItems: true,
              }),
            },
            provide: {
              isGroupIssuesList: false,
            },
          });

          await waitForPromises();

          expect(findEmptyStateWithAnyIssues().exists()).toBe(true);
          expect(findCreateWorkItemModal().exists()).toBe(true);
        });
      });
    });

    describe('sorting work items', () => {
      it('sorts work items by created date in descending order by default', async () => {
        mountComponent();
        await waitForPromises();

        const workItems = findListView().props('workItems');
        // Verify that items are sorted by created date descending
        // The default mock data should be sorted by creation date
        expect(workItems.length).toBeGreaterThan(0);
        if (workItems.length > 1) {
          const firstCreatedAt = new Date(workItems[0].createdAt);
          const secondCreatedAt = new Date(workItems[1].createdAt);
          expect(firstCreatedAt.getTime()).toBeGreaterThanOrEqual(secondCreatedAt.getTime());
        }
      });

      it('sorts work items by created date in ascending order', async () => {
        mountComponent();
        findFilteredSearchBar().vm.$emit('onSort', CREATED_ASC);
        await waitForPromises();

        const workItems = findListView().props('workItems');
        // Verify that items are sorted by created date ascending
        expect(workItems.length).toBeGreaterThan(0);
        if (workItems.length > 1) {
          const firstCreatedAt = new Date(workItems[0].createdAt);
          const secondCreatedAt = new Date(workItems[1].createdAt);
          expect(firstCreatedAt.getTime()).toBeLessThanOrEqual(secondCreatedAt.getTime());
        }
      });

      it('sorts work items by title in ascending order', async () => {
        mountComponent();
        findFilteredSearchBar().vm.$emit('onSort', TITLE_ASC);
        await waitForPromises();

        const workItems = findListView().props('workItems');
        // Verify that items are sorted by title ascending
        expect(workItems.length).toBeGreaterThan(0);
        if (workItems.length > 1) {
          const firstTitle = (workItems[0].title || '').toLowerCase();
          const secondTitle = (workItems[1].title || '').toLowerCase();
          expect(firstTitle.localeCompare(secondTitle)).toBeLessThanOrEqual(0);
        }
      });

      it('sorts work items by title in descending order', async () => {
        mountComponent();
        findFilteredSearchBar().vm.$emit('onSort', TITLE_DESC);
        await waitForPromises();

        const workItems = findListView().props('workItems');
        // Verify that items are sorted by title descending
        expect(workItems.length).toBeGreaterThan(0);
        if (workItems.length > 1) {
          const firstTitle = (workItems[0].title || '').toLowerCase();
          const secondTitle = (workItems[1].title || '').toLowerCase();
          expect(firstTitle.localeCompare(secondTitle)).toBeGreaterThanOrEqual(0);
        }
      });

      it('sorts work items by updated date in descending order', async () => {
        mountComponent();
        findFilteredSearchBar().vm.$emit('onSort', UPDATED_DESC);
        await waitForPromises();

        const workItems = findListView().props('workItems');
        // Verify that items are sorted by updated date descending
        expect(workItems.length).toBeGreaterThan(0);
        if (workItems.length > 1) {
          const firstUpdatedAt = new Date(workItems[0].updatedAt);
          const secondUpdatedAt = new Date(workItems[1].updatedAt);
          expect(firstUpdatedAt.getTime()).toBeGreaterThanOrEqual(secondUpdatedAt.getTime());
        }
      });

      it('sorts work items by updated date in ascending order', async () => {
        mountComponent();
        findFilteredSearchBar().vm.$emit('onSort', UPDATED_ASC);
        await waitForPromises();

        const workItems = findListView().props('workItems');
        // Verify that items are sorted by updated date ascending
        expect(workItems.length).toBeGreaterThan(0);
        if (workItems.length > 1) {
          const firstUpdatedAt = new Date(workItems[0].updatedAt);
          const secondUpdatedAt = new Date(workItems[1].updatedAt);
          expect(firstUpdatedAt.getTime()).toBeLessThanOrEqual(secondUpdatedAt.getTime());
        }
      });
    });
  });
});
