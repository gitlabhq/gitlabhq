import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import WorkItemBulkEditSidebar from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_sidebar.vue';
import WorkItemHealthStatus from '~/work_items/components/work_item_health_status.vue';
import WorkItemListHeading from '~/work_items/components/work_item_list_heading.vue';
import EmptyStateWithoutAnyIssues from '~/issues/list/components/empty_state_without_any_issues.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import waitForPromises from 'helpers/wait_for_promises';
import {
  setSortPreferenceMutationResponse,
  setSortPreferenceMutationResponseWithErrors,
} from 'jest/issues/list/mock_data';
import setWindowLocation from 'helpers/set_window_location_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import { CREATED_DESC, UPDATED_DESC, urlSortParams } from '~/issues/list/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import getUserWorkItemsDisplaySettingsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
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
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import WorkItemUserPreferences from '~/work_items/components/shared/work_item_user_preferences.vue';
import WorkItemsListApp from '~/work_items/pages/work_items_list_app.vue';
import getWorkItemStateCountsQuery from 'ee_else_ce/work_items/graphql/list/get_work_item_state_counts.query.graphql';
import getWorkItemsFullQuery from 'ee_else_ce/work_items/graphql/list/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/graphql/list/get_work_items_slim.query.graphql';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import {
  DETAIL_VIEW_QUERY_PARAM_NAME,
  STATE_CLOSED,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_KEY_RESULT,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WORK_ITEM_TYPE_NAME_TASK,
} from '~/work_items/constants';
import { createRouter } from '~/work_items/router';
import {
  workItemsQueryResponseCombined,
  workItemsQueryResponseNoLabels,
  workItemsQueryResponseNoAssignees,
  groupWorkItemStateCountsQueryResponse,
  combinedQueryResultExample,
} from '../../mock_data';

jest.mock('~/lib/utils/scroll_utils', () => ({ scrollUp: jest.fn() }));
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility');

const showToast = jest.fn();

const skipReason = new SkipReason({
  name: 'WorkItemsListApp component',
  reason: 'Caught error after test environment was torn down',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/478775',
});

describeSkipVue3(skipReason, () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const defaultQueryHandler = jest.fn().mockResolvedValue(workItemsQueryResponseNoLabels);
  const defaultSlimQueryHandler = jest.fn().mockResolvedValue(workItemsQueryResponseNoAssignees);
  const defaultCountsQueryHandler = jest
    .fn()
    .mockResolvedValue(groupWorkItemStateCountsQueryResponse);
  const mutationHandler = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
  const mockPreferencesQueryHandler = jest.fn().mockResolvedValue({
    data: {
      currentUser: null,
    },
  });

  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);
  const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);
  const findWorkItemHealthStatus = () => wrapper.findComponent(WorkItemHealthStatus);
  const findDrawer = () => wrapper.findComponent(WorkItemDrawer);
  const findEmptyStateWithoutAnyIssues = () => wrapper.findComponent(EmptyStateWithoutAnyIssues);
  const findCreateWorkItemModal = () => wrapper.findComponent(CreateWorkItemModal);
  const findBulkEditStartButton = () => wrapper.find('[data-testid="bulk-edit-start-button"]');
  const findBulkEditSidebar = () => wrapper.findComponent(WorkItemBulkEditSidebar);
  const findWorkItemListHeading = () => wrapper.findComponent(WorkItemListHeading);
  const findWorkItemUserPreferences = () => wrapper.findComponent(WorkItemUserPreferences);

  const mountComponent = ({
    provide = {},
    queryHandler = defaultQueryHandler,
    slimQueryHandler = defaultSlimQueryHandler,
    countsQueryHandler = defaultCountsQueryHandler,
    sortPreferenceMutationResponse = mutationHandler,
    mockPreferencesHandler = mockPreferencesQueryHandler,
    workItemsToggleEnabled = true,
    workItemPlanningView = false,
    props = {},
    additionalHandlers = [],
    canReadCrmOrganization = true,
    canReadCrmContact = true,
  } = {}) => {
    window.gon = {
      ...window.gon,
      features: {
        workItemsClientSideBoards: false,
        workItemViewForIssues: workItemsToggleEnabled,
      },
    };
    wrapper = shallowMount(WorkItemsListApp, {
      router: createRouter({ fullPath: '/work_item' }),
      apolloProvider: createMockApollo([
        [getWorkItemsFullQuery, queryHandler],
        [getWorkItemsSlimQuery, slimQueryHandler],
        [getWorkItemStateCountsQuery, countsQueryHandler],
        [setSortPreferenceMutation, sortPreferenceMutationResponse],
        [getUserWorkItemsDisplaySettingsPreferences, mockPreferencesHandler],
        ...additionalHandlers,
      ]),
      provide: {
        glFeatures: {
          okrsMvc: true,
          workItemPlanningView,
        },
        canReadCrmOrganization,
        canReadCrmContact,
        autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
        canBulkUpdate: true,
        canBulkEditEpics: true,
        hasBlockedIssuesFeature: false,
        hasEpicsFeature: false,
        hasGroupBulkEditFeature: true,
        hasIssuableHealthStatusFeature: false,
        hasIssueDateFilterFeature: false,
        hasIssueWeightsFeature: false,
        hasOkrsFeature: false,
        hasQualityManagementFeature: false,
        hasCustomFieldsFeature: false,
        initialSort: CREATED_DESC,
        isGroup: true,
        isSignedIn: true,
        showNewWorkItem: true,
        workItemType: null,
        hasStatusFeature: true,
        ...provide,
      },
      propsData: {
        rootPageFullPath: 'full/path',
        ...props,
      },
      stubs: {
        WorkItemBulkEditSidebar: true,
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
    });
  };

  const mountComponentWithShowParam = async (issue) => {
    const showParams = {
      id: getIdFromGraphQLId(issue.id),
      iid: issue.iid,
      full_path: issue.namespace.fullPath,
    };
    const show = btoa(JSON.stringify(showParams));
    setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);
    getParameterByName.mockReturnValue(show);

    mountComponent({
      provide: {
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
        glFeatures: {
          issuesListDrawer: true,
        },
      },
    });
    await waitForPromises();
    await nextTick();
  };

  it('renders loading icon when initially fetching work items', () => {
    mountComponent();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  describe('when work items are fetched', () => {
    beforeEach(async () => {
      mountComponent();
      await waitForPromises();
    });

    it('renders IssuableList component', () => {
      expect(findIssuableList().props()).toMatchObject({
        currentTab: STATUS_OPEN,
        error: '',
        initialSortBy: CREATED_DESC,
        namespace: 'work-items',
        recentSearchesStorageKey: 'issues',
        showWorkItemTypeIcon: true,
        tabs: WorkItemsListApp.issuableListTabs,
      });
    });

    it('renders the WorkItemUserPreferences component', () => {
      expect(findWorkItemUserPreferences().props()).toMatchObject({
        isEpicsList: false, // default work item is null so not an epics list
        fullPath: 'full/path',
        displaySettings: {
          commonPreferences: { shouldOpenItemsInSidePanel: true },
          namespacePreferences: {},
        },
      });
    });

    it('renders tab counts', () => {
      expect(findIssuableList().props('tabCounts')).toEqual({
        all: 3,
        closed: 1,
        opened: 2,
      });
    });

    it('renders IssueCardStatistics component', () => {
      expect(findIssueCardStatistics().exists()).toBe(true);
    });

    it('renders IssueCardTimeInfo component', () => {
      expect(findIssueCardTimeInfo().exists()).toBe(true);
    });

    it('renders IssueHealthStatus component', () => {
      expect(findWorkItemHealthStatus().exists()).toBe(true);
    });

    it('renders work items', () => {
      expect(findIssuableList().props('issuables')).toEqual(
        workItemsQueryResponseCombined.data.namespace.workItems.nodes,
      );
    });

    it('calls query to fetch work items', () => {
      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          fullPath: 'full/path',
          includeDescendants: true,
          sort: CREATED_DESC,
          state: STATUS_OPEN,
          firstPageSize: 20,
          types: ['ISSUE', 'INCIDENT', 'TASK'],
        }),
      );

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          excludeProjects: false,
        }),
      );
    });

    it('calls `getParameterByName` to get the `show` param', () => {
      expect(getParameterByName).toHaveBeenCalledWith(DETAIL_VIEW_QUERY_PARAM_NAME);
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
          },
        });
        await waitForPromises();

        expect(findIssuableList().props('sortOptions')).toEqual([
          expect.objectContaining({ title: 'Priority' }),
          expect.objectContaining({ title: 'Created date' }),
          expect.objectContaining({ title: 'Updated date' }),
          expect.objectContaining({ title: 'Closed date' }),
          expect.objectContaining({ title: 'Milestone due date' }),
          expect.objectContaining({ title: 'Due date' }),
          expect.objectContaining({ title: 'Popularity' }),
          expect.objectContaining({ title: 'Label priority' }),
          expect.objectContaining({ title: 'Title' }),
          expect.objectContaining({ title: 'Start date' }),
          expect.objectContaining({ title: 'Health' }),
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
          },
        });
        await waitForPromises();

        expect(findIssuableList().props('sortOptions')).toEqual([
          expect.objectContaining({ title: 'Priority' }),
          expect.objectContaining({ title: 'Created date' }),
          expect.objectContaining({ title: 'Updated date' }),
          expect.objectContaining({ title: 'Closed date' }),
          expect.objectContaining({ title: 'Milestone due date' }),
          expect.objectContaining({ title: 'Due date' }),
          expect.objectContaining({ title: 'Popularity' }),
          expect.objectContaining({ title: 'Label priority' }),
          expect.objectContaining({ title: 'Title' }),
          expect.objectContaining({ title: 'Start date' }),
        ]);
      });
    });

    describe('when epics list', () => {
      it('does not render "Priority", "Label priority", and "Weight" sort options', async () => {
        mountComponent({
          provide: {
            hasBlockedIssuesFeature: true,
            hasIssuableHealthStatusFeature: true,
            hasIssueWeightsFeature: true,
            workItemType: WORK_ITEM_TYPE_NAME_EPIC,
          },
        });
        await waitForPromises();

        expect(findIssuableList().props('sortOptions')).toEqual([
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
  });

  describe('pagination controls', () => {
    describe.each`
      description                                                | pageInfo                                          | exists
      ${'when hasNextPage=true and hasPreviousPage=true'}        | ${{ hasNextPage: true, hasPreviousPage: true }}   | ${true}
      ${'when hasNextPage=true'}                                 | ${{ hasNextPage: true, hasPreviousPage: false }}  | ${true}
      ${'when hasPreviousPage=true'}                             | ${{ hasNextPage: false, hasPreviousPage: true }}  | ${true}
      ${'when neither hasNextPage nor hasPreviousPage are true'} | ${{ hasNextPage: false, hasPreviousPage: false }} | ${false}
    `('$description', ({ pageInfo, exists }) => {
      it(`${exists ? 'renders' : 'does not render'} pagination controls`, async () => {
        const response = cloneDeep(workItemsQueryResponseNoLabels);
        Object.assign(response.data.namespace.workItems.pageInfo, pageInfo);
        mountComponent({
          slimQueryHandler: jest.fn().mockResolvedValue(response),
          queryHandler: jest.fn().mockResolvedValue(response),
        });
        await waitForPromises();

        expect(findIssuableList().props('showPaginationControls')).toBe(exists);
      });
    });
  });

  describe('when workItemType is provided', () => {
    it('filters work items by workItemType', async () => {
      mountComponent({ provide: { workItemType: WORK_ITEM_TYPE_NAME_EPIC } });

      await waitForPromises();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          fullPath: 'full/path',
          includeDescendants: true,
          sort: CREATED_DESC,
          state: STATUS_OPEN,
          types: WORK_ITEM_TYPE_ENUM_EPIC,
        }),
      );
    });
  });

  describe('when workItemType Epic is provided', () => {
    it('sends excludeProjects variable in GraphQL query', async () => {
      mountComponent({ provide: { workItemType: WORK_ITEM_TYPE_NAME_EPIC } });

      await waitForPromises();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          excludeProjects: true,
        }),
      );
    });
  });

  describe('slim and full queries', () => {
    beforeEach(() => {
      mountComponent();

      return waitForPromises();
    });

    it('calls the slim query as well as the full query', () => {
      expect(defaultQueryHandler).toHaveBeenCalled();
      expect(defaultSlimQueryHandler).toHaveBeenCalled();
    });

    it('combines the slim and full results correctly and passes the to the list component', () => {
      expect(findIssuableList().props('issuables')).toEqual(combinedQueryResultExample);
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
      await waitForPromises();
    });

    it('renders an error message', () => {
      expect(findIssuableList().props('error')).toBe(message);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
    });

    it('clears error message when "dismiss-alert" event is emitted from IssuableList', async () => {
      findIssuableList().vm.$emit('dismiss-alert');
      await nextTick();

      expect(wrapper.text()).not.toContain(message);
    });
  });

  describe('watcher', () => {
    describe('when eeCreatedWorkItemsCount is updated', () => {
      it('refetches work items', async () => {
        mountComponent();
        await waitForPromises();

        expect(defaultQueryHandler).toHaveBeenCalledTimes(1);
        expect(defaultCountsQueryHandler).toHaveBeenCalledTimes(1);

        await wrapper.setProps({ eeWorkItemUpdateCount: 1 });

        expect(defaultQueryHandler).toHaveBeenCalledTimes(2);
        expect(defaultCountsQueryHandler).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('tokens', () => {
    it('renders tokens', async () => {
      mountComponent();
      await waitForPromises();
      const tokens = findIssuableList()
        .props('searchTokens')
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
        TOKEN_TYPE_SEARCH_WITHIN,
        TOKEN_TYPE_SUBSCRIBED,
        TOKEN_TYPE_TYPE,
      ]);
    });

    describe('when workItemType is defined', () => {
      it('renders all tokens except "Type"', async () => {
        mountComponent({ provide: { workItemType: WORK_ITEM_TYPE_NAME_EPIC } });
        await waitForPromises();
        const tokens = findIssuableList()
          .props('searchTokens')
          .map((token) => token.type);

        expect(tokens).not.toContain(TOKEN_TYPE_TYPE);
      });
    });

    describe('when hasIssueDateFilterFeature is available', () => {
      it('renders date-related tokens too', async () => {
        mountComponent({ provide: { hasIssueDateFilterFeature: true } });
        await waitForPromises();
        const tokens = findIssuableList()
          .props('searchTokens')
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
          TOKEN_TYPE_SEARCH_WITHIN,
          TOKEN_TYPE_SUBSCRIBED,
          TOKEN_TYPE_TYPE,
          TOKEN_TYPE_UPDATED,
        ]);
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
        const tokens = findIssuableList()
          .props('searchTokens')
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
          TOKEN_TYPE_SEARCH_WITHIN,
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
          const organizationToken = findIssuableList()
            .props('searchTokens')
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
          const tokens = findIssuableList()
            .props('searchTokens')
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
          const contactToken = findIssuableList()
            .props('searchTokens')
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
          const tokens = findIssuableList()
            .props('searchTokens')
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
  });

  describe('events', () => {
    describe('when "click-tab" event is emitted by IssuableList', () => {
      beforeEach(async () => {
        getParameterByName.mockImplementation((args) =>
          jest.requireActual('~/lib/utils/url_utility').getParameterByName(args),
        );
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('click-tab', STATUS_CLOSED);
      });

      it('updates ui to the new tab', () => {
        expect(findIssuableList().props('currentTab')).toBe(STATUS_CLOSED);
      });
    });

    describe('when "filter" event is emitted by IssuableList', () => {
      it('fetches filtered work items', async () => {
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('filter', [
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

    describe.each`
      event              | params
      ${'next-page'}     | ${{ afterCursor: 'endCursor', firstPageSize: 20 }}
      ${'previous-page'} | ${{ beforeCursor: 'startCursor', lastPageSize: 20 }}
    `('when "$event" event is emitted by IssuableList', ({ event, params }) => {
      beforeEach(async () => {
        getParameterByName.mockImplementation((args) =>
          jest.requireActual('~/lib/utils/url_utility').getParameterByName(args),
        );
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit(event);
      });

      it('scrolls to the top', () => {
        expect(scrollUp).toHaveBeenCalled();
      });

      it('fetches next/previous work items', () => {
        expect(defaultQueryHandler).toHaveBeenLastCalledWith(expect.objectContaining(params));
      });
    });

    describe('when "page-size-change" event is emitted by IssuableList', () => {
      it('updates list with new page size', async () => {
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('page-size-change', 50);
        await nextTick();

        expect(defaultQueryHandler).toHaveBeenLastCalledWith(
          expect.objectContaining({ firstPageSize: 50 }),
        );
      });
    });

    describe('when "sort" event is emitted by IssuableList', () => {
      it.each(Object.keys(urlSortParams))(
        'updates to the new sort when payload is `%s`',
        async (sortKey) => {
          // Ensure initial sort key is different so we trigger an update when emitting a sort key
          if (sortKey === CREATED_DESC) {
            mountComponent({ provide: { initialSort: UPDATED_DESC } });
          } else {
            mountComponent();
          }
          await waitForPromises();

          findIssuableList().vm.$emit('sort', sortKey);
          await waitForPromises();

          expect(defaultQueryHandler).toHaveBeenCalledWith(
            expect.objectContaining({ sort: sortKey }),
          );
        },
      );

      describe('when user is signed in', () => {
        it('calls mutation to save sort preference', async () => {
          mountComponent();
          await waitForPromises();

          findIssuableList().vm.$emit('sort', UPDATED_DESC);

          expect(mutationHandler).toHaveBeenCalledWith({ input: { issuesSort: UPDATED_DESC } });
        });

        it('captures error when mutation response has errors', async () => {
          const mutationMock = jest
            .fn()
            .mockResolvedValue(setSortPreferenceMutationResponseWithErrors);
          mountComponent({ sortPreferenceMutationResponse: mutationMock });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', UPDATED_DESC);
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
        });
      });

      describe('when user is signed out', () => {
        it('does not call mutation to save sort preference', async () => {
          mountComponent({ provide: { isSignedIn: false } });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', CREATED_DESC);

          expect(mutationHandler).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('work item drawer', () => {
    describe('when rendering issues list', () => {
      describe('when issues_list_drawer feature is disabled', () => {
        it('is not rendered when feature is disabled', async () => {
          mountComponent({
            workItemsToggleEnabled: false,
            provide: {
              glFeatures: {
                issuesListDrawer: false,
                epicsListDrawer: true,
              },
            },
          });
          await waitForPromises();

          expect(findDrawer().exists()).toBe(false);
        });
      });

      describe('when issues_list_drawer feature is enabled', () => {
        beforeEach(async () => {
          mountComponent({
            provide: {
              glFeatures: {
                issuesListDrawer: true,
                epicsListDrawer: false,
              },
            },
          });
          await waitForPromises();
        });

        it.each`
          message              | shouldOpenItemsInSidePanel | drawerExists
          ${'is rendered'}     | ${true}                    | ${true}
          ${'is not rendered'} | ${false}                   | ${false}
        `(
          '$message when shouldOpenItemsInSidePanel is $shouldOpenItemsInSidePanel',
          async ({ shouldOpenItemsInSidePanel, drawerExists }) => {
            const mockHandler = jest.fn().mockResolvedValue({
              data: {
                currentUser: {
                  id: 'gid://gitlab/User/1',
                  userPreferences: {
                    workItemsDisplaySettings: { shouldOpenItemsInSidePanel },
                  },
                  workItemPreferences: {
                    displaySettings: { hiddenMetadataKeys: [] },
                  },
                },
              },
            });

            mountComponent({
              mockPreferencesHandler: mockHandler,
              provide: {
                glFeatures: {
                  workItemViewForIssues: false,
                  epicsListDrawer: false,
                  issuesListDrawer: true,
                },
                isSignedIn: true,
              },
            });

            await waitForPromises();

            expect(findDrawer().exists()).toBe(drawerExists);
          },
        );
        describe('display settings', () => {
          it('passes hiddenMetadataKeys to IssuableList', async () => {
            const mockHandler = jest.fn().mockResolvedValue({
              data: {
                currentUser: {
                  id: 'gid://gitlab/User/1',
                  userPreferences: {
                    workItemsDisplaySettings: { shouldOpenItemsInSidePanel: true },
                  },
                  workItemPreferences: {
                    displaySettings: { hiddenMetadataKeys: ['labels', 'milestone'] },
                  },
                },
              },
            });

            mountComponent({ mockPreferencesHandler: mockHandler });
            await waitForPromises();

            expect(findIssuableList().props('hiddenMetadataKeys')).toEqual(['labels', 'milestone']);
          });

          it('passes hiddenMetadataKeys to IssueCardTimeInfo', async () => {
            const mockHandler = jest.fn().mockResolvedValue({
              data: {
                currentUser: {
                  id: 'gid://gitlab/User/1',
                  userPreferences: {
                    workItemsDisplaySettings: { shouldOpenItemsInSidePanel: true },
                  },
                  workItemPreferences: {
                    displaySettings: { hiddenMetadataKeys: ['dates', 'milestone'] },
                  },
                },
              },
            });

            mountComponent({ mockPreferencesHandler: mockHandler });
            await waitForPromises();

            expect(findIssueCardTimeInfo().props('hiddenMetadataKeys')).toEqual([
              'dates',
              'milestone',
            ]);
          });

          describe('workItemDrawerEnabled', () => {
            it('does not render drawer when shouldOpenItemsInSidePanel is false', async () => {
              const mockHandler = jest.fn().mockResolvedValue({
                data: {
                  currentUser: {
                    id: 'gid://gitlab/User/1',
                    userPreferences: {
                      workItemsDisplaySettings: { shouldOpenItemsInSidePanel: false },
                    },
                    workItemPreferences: {
                      displaySettings: { hiddenMetadataKeys: [] },
                    },
                  },
                },
              });

              mountComponent({ mockPreferencesHandler: mockHandler });
              await waitForPromises();

              expect(findDrawer().exists()).toBe(false);
            });

            it('renders drawer when shouldOpenItemsInSidePanel is true and feature is enabled', async () => {
              const mockHandler = jest.fn().mockResolvedValue({
                data: {
                  currentUser: {
                    id: 'gid://gitlab/User/1',
                    userPreferences: {
                      workItemsDisplaySettings: { shouldOpenItemsInSidePanel: true },
                    },
                    workItemPreferences: {
                      displaySettings: { hiddenMetadataKeys: [] },
                    },
                  },
                },
              });

              mountComponent({
                mockPreferencesHandler: mockHandler,
                provide: {
                  glFeatures: {
                    workItemViewForIssues: false,
                    epicsListDrawer: false,
                    issuesListDrawer: true,
                  },
                },
              });
              await waitForPromises();

              expect(findDrawer().exists()).toBe(true);
            });
          });
        });

        describe('selecting issues', () => {
          const issue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[0];
          const payload = {
            iid: issue.iid,
            webUrl: issue.webUrl,
            fullPath: issue.namespace.fullPath,
          };

          beforeEach(async () => {
            findIssuableList().vm.$emit('select-issuable', payload);

            await nextTick();
          });

          it('opens drawer when work item is selected', () => {
            expect(findDrawer().props('open')).toBe(true);
            expect(findDrawer().props('activeItem')).toEqual(payload);
          });

          it('closes drawer when work item is clicked again', async () => {
            findIssuableList().vm.$emit('select-issuable', payload);
            await nextTick();

            expect(findDrawer().props('open')).toBe(false);
            expect(findDrawer().props('activeItem')).toBeNull();
          });

          const checkThatDrawerPropsAreEmpty = () => {
            expect(findDrawer().props('activeItem')).toBeNull();
            expect(findDrawer().props('open')).toBe(false);
          };

          it('resets the selected item when the drawer is closed', async () => {
            findDrawer().vm.$emit('close');

            await nextTick();

            checkThatDrawerPropsAreEmpty();
          });

          it('refetches counts and resets when work item is deleted', async () => {
            expect(defaultCountsQueryHandler).toHaveBeenCalledTimes(1);

            findDrawer().vm.$emit('workItemDeleted');

            await nextTick();

            checkThatDrawerPropsAreEmpty();

            expect(defaultCountsQueryHandler).toHaveBeenCalledTimes(2);
          });

          it('refetches counts when the selected work item is closed', async () => {
            expect(defaultCountsQueryHandler).toHaveBeenCalledTimes(1);

            // component displays open work items by default
            findDrawer().vm.$emit('work-item-updated', {
              state: STATE_CLOSED,
            });

            await nextTick();

            expect(defaultCountsQueryHandler).toHaveBeenCalledTimes(2);
          });
        });
      });
    });

    describe('when rendering epics list', () => {
      describe('when epics_list_drawer feature is disabled', () => {
        it('is not rendered when feature is disabled', async () => {
          mountComponent({
            workItemsToggleEnabled: false,
            provide: {
              glFeatures: {
                issuesListDrawer: true,
                epicsListDrawer: false,
              },
              workItemType: WORK_ITEM_TYPE_NAME_EPIC,
            },
          });
          await waitForPromises();

          expect(findDrawer().exists()).toBe(false);
        });
      });

      describe('when issues_list_drawer feature is enabled', () => {
        beforeEach(async () => {
          mountComponent({
            provide: {
              glFeatures: {
                issuesListDrawer: false,
                epicsListDrawer: true,
              },
              workItemType: WORK_ITEM_TYPE_NAME_EPIC,
            },
          });
          await waitForPromises();
        });

        it('is rendered when feature is enabled', () => {
          expect(findDrawer().exists()).toBe(true);
        });
      });
    });

    describe('When the `show` parameter matches an item in the list', () => {
      it('displays the item in the drawer', async () => {
        const issue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[0];
        await mountComponentWithShowParam(issue);

        expect(findDrawer().props('open')).toBe(true);
        expect(findDrawer().props('activeItem')).toMatchObject(issue);
      });
    });

    describe('When the `show` parameter does not match an item in the list', () => {
      beforeEach(async () => {
        const showParams = { id: 9999, iid: '9999', full_path: 'does/not/match' };
        const show = btoa(JSON.stringify(showParams));
        setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);
        getParameterByName.mockReturnValue(show);
        mountComponent({
          provide: {
            workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
            glFeatures: {
              issuesListDrawer: true,
            },
          },
        });
        await waitForPromises();
      });
      it('calls `updateHistory', () => {
        expect(updateHistory).toHaveBeenCalled();
      });
      it('calls `removeParams` to remove the `show` param', () => {
        expect(removeParams).toHaveBeenCalledWith([DETAIL_VIEW_QUERY_PARAM_NAME]);
      });
    });

    describe('when window `popstate` event is triggered', () => {
      it('closes the drawer if there is no `show` param', async () => {
        const issue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[0];
        await mountComponentWithShowParam(issue);
        expect(findDrawer().props('open')).toBe(true);
        expect(findDrawer().props('activeItem')).toMatchObject(issue);

        setWindowLocation('?');
        window.dispatchEvent(new Event('popstate'));

        await nextTick();
        expect(findDrawer().props('open')).toBe(false);
      });

      it('updates the drawer with the new item if there is a `show` param', async () => {
        const issue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[0];
        const nextIssue = workItemsQueryResponseCombined.data.namespace.workItems.nodes[1];
        await mountComponentWithShowParam(issue);

        expect(findDrawer().props('open')).toBe(true);
        expect(findDrawer().props('activeItem')).toMatchObject(issue);

        const showParams = {
          id: getIdFromGraphQLId(nextIssue.id),
          iid: nextIssue.iid,
          full_path: nextIssue.namespace.fullPath,
        };
        const show = btoa(JSON.stringify(showParams));
        setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);

        window.dispatchEvent(new Event('popstate'));
        await waitForPromises();

        expect(findDrawer().props('open')).toBe(true);
        expect(findDrawer().props('activeItem')).toMatchObject(issue);
      });
    });
  });

  describe('when withTabs is false', () => {
    beforeEach(async () => {
      mountComponent({ props: { withTabs: false } });
      await waitForPromises();
    });
    it('includes "State", in searchTokens', () => {
      expect(
        findIssuableList()
          .props('searchTokens')
          .map((token) => token.type),
      ).toContain(TOKEN_TYPE_STATE);
    });
    it('passes empty array in the tabs props', () => {
      expect(findIssuableList().props('tabs')).toEqual([]);
    });
  });

  describe('empty states', () => {
    const emptyWorkItemsResponse = cloneDeep(workItemsQueryResponseNoLabels);
    emptyWorkItemsResponse.data.namespace.workItems.nodes = [];

    const emptyWorkItemsSlimResponse = cloneDeep(workItemsQueryResponseNoAssignees);
    emptyWorkItemsSlimResponse.data.namespace.workItems.nodes = [];

    const emptyCountsResponse = cloneDeep(groupWorkItemStateCountsQueryResponse);
    emptyCountsResponse.data.group.workItemStateCounts = {
      all: 0,
      closed: 0,
      opened: 0,
    };

    describe('when filters are applied and no work items match', () => {
      beforeEach(async () => {
        setWindowLocation('?label_name=bug');
        mountComponent({
          queryHandler: jest.fn().mockResolvedValue(emptyWorkItemsResponse),
          slimQueryHandler: jest.fn().mockResolvedValue(emptyWorkItemsSlimResponse),
          countsQueryHandler: jest.fn().mockResolvedValue(emptyCountsResponse),
        });
        await waitForPromises();
      });

      it('renders IssuableList component with empty results', () => {
        expect(findIssuableList().exists()).toBe(true);
        expect(findIssuableList().props('issuables')).toEqual([]);
      });
    });

    describe('when there are no work items', () => {
      beforeEach(async () => {
        mountComponent({
          queryHandler: jest.fn().mockResolvedValue(emptyWorkItemsResponse),
          slimQueryHandler: jest.fn().mockResolvedValue(emptyWorkItemsSlimResponse),
          countsQueryHandler: jest.fn().mockResolvedValue(emptyCountsResponse),
        });
        await waitForPromises();
      });

      it('renders the list empty state', () => {
        expect(findEmptyStateWithoutAnyIssues().exists()).toBe(true);
      });
    });
  });

  describe('group filter', () => {
    describe('filtering by group', () => {
      it('query excludes descendants and excludes projects', async () => {
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('filter', [
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
      it('query includes descendants and includes projects', async () => {
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('filter', [
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
  });

  describe('when issue_date_filter is enabled', () => {
    it('includes created and closed date in searchTokens', async () => {
      mountComponent({ provide: { hasIssueDateFilterFeature: true } });
      await waitForPromises();

      const tokenTypes = findIssuableList()
        .props('searchTokens')
        .map((token) => token.type);

      expect(tokenTypes).toEqual(expect.arrayContaining([TOKEN_TYPE_CLOSED, TOKEN_TYPE_CREATED]));
    });
  });

  describe('CreateWorkItem modal', () => {
    it.each([true, false])('renders depending on showNewWorkItem=%s', async (showNewWorkItem) => {
      mountComponent({ provide: { showNewWorkItem } });
      await waitForPromises();

      expect(findCreateWorkItemModal().exists()).toBe(showNewWorkItem);
    });

    describe('allowedWorkItemTypes', () => {
      it('returns empty array when group', async () => {
        mountComponent({ provide: { isGroup: true } });
        await waitForPromises();

        expect(findCreateWorkItemModal().props('allowedWorkItemTypes')).toEqual([]);
      });

      it('returns project-level types when project', async () => {
        mountComponent({ provide: { isGroup: false } });
        await waitForPromises();

        expect(findCreateWorkItemModal().props('allowedWorkItemTypes')).toEqual([
          WORK_ITEM_TYPE_NAME_INCIDENT,
          WORK_ITEM_TYPE_NAME_ISSUE,
          WORK_ITEM_TYPE_NAME_TASK,
        ]);
      });

      it('returns project-level types including okr types when project and when okrs is enabled', async () => {
        mountComponent({ provide: { isGroup: false, hasOkrsFeature: true } });
        await waitForPromises();

        expect(findCreateWorkItemModal().props('allowedWorkItemTypes')).toEqual([
          WORK_ITEM_TYPE_NAME_INCIDENT,
          WORK_ITEM_TYPE_NAME_ISSUE,
          WORK_ITEM_TYPE_NAME_TASK,
          WORK_ITEM_TYPE_NAME_KEY_RESULT,
          WORK_ITEM_TYPE_NAME_OBJECTIVE,
        ]);
      });
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

  describe('when bulk editing', () => {
    describe('user permissions', () => {
      describe('when workItemType=Epic', () => {
        it.each([true, false])('renders=$s when canBulkEditEpics=%s', async (canBulkEditEpics) => {
          mountComponent({ provide: { canBulkEditEpics, workItemType: WORK_ITEM_TYPE_NAME_EPIC } });
          await waitForPromises();

          expect(findBulkEditStartButton().exists()).toBe(canBulkEditEpics);
        });
      });

      describe('when group', () => {
        it.each`
          canBulkUpdate | hasGroupBulkEditFeature | renders
          ${true}       | ${true}                 | ${true}
          ${true}       | ${false}                | ${false}
          ${false}      | ${true}                 | ${false}
          ${false}      | ${false}                | ${false}
        `(
          'renders=$renders when canBulkUpdate=$canBulkUpdate and hasGroupBulkEditFeature=$hasGroupBulkEditFeature',
          async ({ canBulkUpdate, hasGroupBulkEditFeature, renders }) => {
            mountComponent({ provide: { isGroup: true, canBulkUpdate, hasGroupBulkEditFeature } });
            await waitForPromises();

            expect(findBulkEditStartButton().exists()).toBe(renders);
          },
        );
      });

      describe('when project', () => {
        it.each([true, false])('renders depending on canBulkUpdate=%s', async (canBulkUpdate) => {
          mountComponent({ provide: { isGroup: false, canBulkUpdate } });
          await waitForPromises();

          expect(findBulkEditStartButton().exists()).toBe(canBulkUpdate);
        });
      });
    });

    it('closes the bulk edit sidebar when the "success" event is emitted', async () => {
      mountComponent();
      await waitForPromises();

      findBulkEditStartButton().vm.$emit('click');
      await waitForPromises();

      expect(findIssuableList().props('showBulkEditSidebar')).toBe(true);

      findBulkEditSidebar().vm.$emit('success');
      await nextTick();

      expect(findIssuableList().props('showBulkEditSidebar')).toBe(false);
    });

    it('does not close the bulk edit sidebar when no "success" event is emitted', async () => {
      mountComponent();
      await waitForPromises();

      findBulkEditStartButton().vm.$emit('click');
      await waitForPromises();

      expect(findIssuableList().props('showBulkEditSidebar')).toBe(true);

      findBulkEditSidebar().vm.$emit('finish');
      await nextTick();

      expect(findIssuableList().props('showBulkEditSidebar')).toBe(true);
    });

    it('creates a toast when the success event includes a toast message', async () => {
      mountComponent();
      await waitForPromises();

      findBulkEditStartButton().vm.$emit('click');
      await waitForPromises();

      expect(findIssuableList().props('showBulkEditSidebar')).toBe(true);

      findBulkEditSidebar().vm.$emit('success', { toastMessage: 'hello!' });
      await nextTick();

      expect(showToast).toHaveBeenCalledWith('hello!');
    });
  });

  describe('when workItemPlanningView flag is enabled', () => {
    it('renders the WorkItemListHeading component', async () => {
      mountComponent({ workItemPlanningView: true });
      await waitForPromises();

      expect(findWorkItemListHeading().exists()).toBe(true);
    });
  });
});
