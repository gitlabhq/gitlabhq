import { GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { cloneDeep } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import getIssuesCountsQuery from 'ee_else_ce/issues/list/queries/get_issues_counts.query.graphql';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import {
  filteredTokens,
  getIssuesCountsQueryResponse,
  getIssuesQueryEmptyResponse,
  getIssuesQueryResponse,
  groupedFilteredTokens,
  locationSearch,
  setSortPreferenceMutationResponse,
  setSortPreferenceMutationResponseWithErrors,
  urlParams,
} from 'jest/issues/list/mock_data';
import { createAlert, VARIANT_INFO } from '~/alert';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import EmptyStateWithAnyIssues from '~/issues/list/components/empty_state_with_any_issues.vue';
import EmptyStateWithoutAnyIssues from '~/issues/list/components/empty_state_without_any_issues.vue';
import IssuesListApp from '~/issues/list/components/issues_list_app.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import {
  CREATED_DESC,
  RELATIVE_POSITION,
  RELATIVE_POSITION_ASC,
  UPDATED_DESC,
  urlSortParams,
} from '~/issues/list/constants';
import eventHub from '~/issues/list/eventhub';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { getSortKey, getSortOptions } from '~/issues/list/utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { scrollUp } from '~/lib/utils/scroll_utils';
import {
  joinPaths,
  getParameterByName,
  updateHistory,
  removeParams,
} from '~/lib/utils/url_utility';
import {
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_TASK,
  DETAIL_VIEW_QUERY_PARAM_NAME,
} from '~/work_items/constants';
import {
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_CONTACT,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_ORGANIZATION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_CREATED,
  TOKEN_TYPE_CLOSED,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  workItemResponseFactory,
  workItemByIidResponseFactory,
  mockAwardEmojiThumbsUp,
  mockAwardsWidget,
  mockAssignees,
  mockLabels,
  mockMilestone,
} from 'jest/work_items/mock_data';

import('~/issuable');
import('~/users_select');

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/alert');
jest.mock('~/lib/utils/scroll_utils', () => ({ scrollUp: jest.fn() }));
jest.mock('~/lib/utils/url_utility');

describe('CE IssuesListApp component', () => {
  let axiosMock;
  let wrapper;

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const fullPath = 'path/to/project';

  const defaultProvide = {
    autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
    calendarPath: 'calendar/path',
    canBulkUpdate: false,
    canCreateIssue: false,
    canCreateProjects: false,
    canReadCrmContact: false,
    canReadCrmOrganization: false,
    exportCsvPath: 'export/csv/path',
    fullPath,
    hasAnyIssues: true,
    hasAnyProjects: true,
    hasBlockedIssuesFeature: true,
    hasIssueDateFilterFeature: true,
    hasIssuableHealthStatusFeature: true,
    hasIssueWeightsFeature: true,
    hasIterationsFeature: true,
    hasOkrsFeature: false,
    hasQualityManagementFeature: false,
    hasScopedLabelsFeature: true,
    initialEmail: 'email@example.com',
    initialSort: CREATED_DESC,
    isIssueRepositioningDisabled: false,
    isProject: true,
    isPublicVisibilityRestricted: false,
    isSignedIn: true,
    newIssuePath: 'new/issue/path',
    newProjectPath: 'new/project/path',
    releasesPath: 'releases/path',
    rssPath: 'rss/path',
    showNewIssueLink: true,
    signInPath: 'sign/in/path',
    groupId: '',
    commentTemplatePaths: [],
  };

  let defaultQueryResponse = getIssuesQueryResponse;
  /** @type {import('vue-router').default} */
  let router;
  if (IS_EE) {
    defaultQueryResponse = cloneDeep(getIssuesQueryResponse);
    defaultQueryResponse.data.project.issues.nodes[0].blockingCount = 1;
    defaultQueryResponse.data.project.issues.nodes[0].healthStatus = null;
    defaultQueryResponse.data.project.issues.nodes[0].weight = 5;
    defaultQueryResponse.data.project.issues.nodes[0].epic = {
      id: 'gid://gitlab/Epic/1',
    };
  }

  const mockIssuesQueryResponse = jest.fn().mockResolvedValue(defaultQueryResponse);
  const mockIssuesCountsQueryResponse = jest.fn().mockResolvedValue(getIssuesCountsQueryResponse);

  const findCsvImportExportButtons = () => wrapper.findComponent(CsvImportExportButtons);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findIssuableByEmail = () => wrapper.findComponent(IssuableByEmail);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlButtons = () => wrapper.findAllComponents(GlButton);
  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findListViewTypeBtn = () => wrapper.findByTestId('list-view-type');
  const findGridtViewTypeBtn = () => wrapper.findByTestId('grid-view-type');
  const findViewTypeLocalStorageSync = () => wrapper.findAllComponents(LocalStorageSync).at(0);
  const findNewResourceDropdown = () => wrapper.findComponent(NewResourceDropdown);
  const findCalendarButton = () => wrapper.findByTestId('subscribe-calendar');
  const findRssButton = () => wrapper.findByTestId('subscribe-rss');
  const findWorkItemDrawer = () => wrapper.findComponent(WorkItemDrawer);
  const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);
  const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);

  const findLabelsToken = () =>
    findIssuableList()
      .props('searchTokens')
      .find((token) => token.type === TOKEN_TYPE_LABEL);

  const mountComponent = ({
    provide = {},
    data = {},
    issuesQueryResponse = mockIssuesQueryResponse,
    issuesCountsQueryResponse = mockIssuesCountsQueryResponse,
    sortPreferenceMutationResponse = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse),
    stubs = {},
    mountFn = shallowMount,
  } = {}) => {
    const requestHandlers = [
      [getIssuesQuery, issuesQueryResponse],
      [getIssuesCountsQuery, issuesCountsQueryResponse],
      [setSortPreferenceMutation, sortPreferenceMutationResponse],
    ];

    router = new VueRouter({ mode: 'history' });

    return mountFn(IssuesListApp, {
      apolloProvider: createMockApollo(
        requestHandlers,
        {},
        {
          typePolicies: {
            Query: {
              fields: {
                project: {
                  merge: true,
                },
                group: {
                  merge: true,
                },
              },
            },
          },
        },
      ),
      router,
      provide: {
        ...defaultProvide,
        ...provide,
      },
      data() {
        return data;
      },
      stubs,
    });
  };

  beforeEach(() => {
    setWindowLocation(TEST_HOST);
    axiosMock = new AxiosMockAdapter(axios);
    joinPaths.mockImplementation((args) =>
      jest.requireActual('~/lib/utils/url_utility').joinPaths(args),
    );
  });

  afterEach(() => {
    axiosMock.reset();
  });

  describe('IssuableList', () => {
    beforeEach(() => {
      wrapper = mountComponent();
      return waitForPromises();
    });

    it('renders', () => {
      expect(findIssuableList().props()).toMatchObject({
        namespace: defaultProvide.fullPath,
        recentSearchesStorageKey: 'issues',
        sortOptions: getSortOptions({
          hasBlockedIssuesFeature: defaultProvide.hasBlockedIssuesFeature,
          hasIssuableHealthStatusFeature: defaultProvide.hasIssuableHealthStatusFeature,
          hasIssueWeightsFeature: defaultProvide.hasIssueWeightsFeature,
        }),
        initialSortBy: CREATED_DESC,
        issuables: getIssuesQueryResponse.data.project.issues.nodes,
        tabs: issuableListTabs,
        currentTab: STATUS_OPEN,
        tabCounts: {
          opened: 1,
          closed: 1,
          all: 1,
        },
        issuablesLoading: false,
        isManualOrdering: false,
        showBulkEditSidebar: false,
        showPaginationControls: true,
        useKeysetPagination: true,
        hasPreviousPage: getIssuesQueryResponse.data.project.issues.pageInfo.hasPreviousPage,
        hasNextPage: getIssuesQueryResponse.data.project.issues.pageInfo.hasNextPage,
      });
      expect(findIssuableList().props('isGridView')).toBe(false);
    });
  });

  describe('header action buttons', () => {
    describe('actions dropdown', () => {
      it('renders', () => {
        wrapper = mountComponent({ mountFn: mount });

        expect(findDropdown().props()).toMatchObject({
          category: 'tertiary',
          icon: 'ellipsis_v',
          toggleText: 'Actions',
          textSrOnly: true,
        });
      });

      describe('csv import/export buttons', () => {
        describe('when user is signed in', () => {
          beforeEach(() => {
            setWindowLocation('?search=refactor&state=opened');

            wrapper = mountComponent({
              provide: { initialSortBy: CREATED_DESC, isSignedIn: true },
              mountFn: mount,
            });

            return waitForPromises();
          });

          it('renders', () => {
            expect(findCsvImportExportButtons().props()).toMatchObject({
              exportCsvPath: `${defaultProvide.exportCsvPath}?search=refactor&state=opened`,
              issuableCount: 1,
            });
          });
        });

        describe('when user is not signed in', () => {
          it('does not render', () => {
            wrapper = mountComponent({ provide: { isSignedIn: false }, mountFn: mount });

            expect(findCsvImportExportButtons().exists()).toBe(false);
          });
        });

        describe('when in a group context', () => {
          it('does not render', () => {
            wrapper = mountComponent({ provide: { isProject: false }, mountFn: mount });

            expect(findCsvImportExportButtons().exists()).toBe(false);
          });
        });
      });

      it('renders RSS button link', () => {
        wrapper = mountComponent({ mountFn: mountExtended });

        expect(findRssButton().attributes('href')).toBe(defaultProvide.rssPath);
      });

      it('renders calendar button link', () => {
        wrapper = mountComponent({ mountFn: mountExtended });

        expect(findCalendarButton().attributes('href')).toBe(defaultProvide.calendarPath);
      });
    });

    describe('bulk edit button', () => {
      it('renders when user has permissions', () => {
        wrapper = mountComponent({ provide: { canBulkUpdate: true }, mountFn: mount });

        expect(findGlButton().text()).toBe('Bulk edit');
      });

      it('does not render when user does not have permissions', () => {
        wrapper = mountComponent({ provide: { canBulkUpdate: false }, mountFn: mount });

        expect(findGlButtons().filter((button) => button.text() === 'Bulk edit')).toHaveLength(0);
      });

      it('emits "issuables:enableBulkEdit" event to legacy bulk edit class', async () => {
        wrapper = mountComponent({ provide: { canBulkUpdate: true }, mountFn: mount });
        jest.spyOn(eventHub, '$emit');

        findGlButton().vm.$emit('click');
        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith('issuables:enableBulkEdit');
      });
    });

    describe('new issue button', () => {
      it('renders when user has permissions', () => {
        wrapper = mountComponent({ provide: { showNewIssueLink: true }, mountFn: mount });

        expect(findGlButton().text()).toBe('New issue');
        expect(findGlButton().attributes('href')).toBe(defaultProvide.newIssuePath);
      });

      it('does not render when user does not have permissions', () => {
        wrapper = mountComponent({ provide: { showNewIssueLink: false }, mountFn: mount });

        expect(findGlButtons().filter((button) => button.text() === 'New issue')).toHaveLength(0);
      });
    });

    describe('new issue split dropdown', () => {
      it('does not render in a project context', () => {
        wrapper = mountComponent({ provide: { isProject: true }, mountFn: mount });

        expect(findNewResourceDropdown().exists()).toBe(false);
      });

      it('renders in a group context', () => {
        wrapper = mountComponent({ provide: { isProject: false }, mountFn: mount });

        expect(findNewResourceDropdown().exists()).toBe(true);
      });
    });
  });

  describe('header action buttons with the grid view enabled', () => {
    beforeEach(() => {
      wrapper = mountComponent({
        mountFn: shallowMountExtended,
        provide: {
          glFeatures: {
            issuesGridView: true,
          },
        },
        stubs: {
          IssuableList: stubComponent(IssuableList, {
            template: `<div><slot name="nav-actions" /></div>`,
          }),
        },
      });
    });

    it('switch between list and grid', async () => {
      findGridtViewTypeBtn().vm.$emit('click');
      await nextTick();

      expect(findIssuableList().props('isGridView')).toBe(true);
      expect(findViewTypeLocalStorageSync().props('value')).toBe('Grid');

      findListViewTypeBtn().vm.$emit('click');
      await nextTick();
      expect(findIssuableList().props('isGridView')).toBe(false);
      expect(findViewTypeLocalStorageSync().props('value')).toBe('List');
    });
  });

  describe('initial url params', () => {
    describe('page', () => {
      it('page_after is set from the url params', () => {
        setWindowLocation('?page_after=randomCursorString&first_page_size=20');
        wrapper = mountComponent();

        expect(wrapper.vm.$route.query).toMatchObject({
          page_after: 'randomCursorString',
          first_page_size: '20',
        });
      });

      it('page_before is set from the url params', () => {
        setWindowLocation('?page_before=anotherRandomCursorString&last_page_size=20');
        wrapper = mountComponent();

        expect(wrapper.vm.$route.query).toMatchObject({
          page_before: 'anotherRandomCursorString',
          last_page_size: '20',
        });
      });
    });

    describe('search', () => {
      it('is set from the url params', () => {
        setWindowLocation(locationSearch);
        wrapper = mountComponent();

        expect(wrapper.vm.$route.query).toMatchObject({ search: 'find issues' });
      });
    });

    describe('sort', () => {
      describe('when initial sort value uses old enum values', () => {
        const oldEnumSortValues = Object.values(urlSortParams);

        it.each(oldEnumSortValues)('initial sort is set with value %s', (sort) => {
          wrapper = mountComponent({ provide: { initialSort: sort } });

          expect(findIssuableList().props('initialSortBy')).toBe(getSortKey(sort));
        });
      });

      describe('when initial sort value uses new GraphQL enum values', () => {
        const graphQLEnumSortValues = Object.keys(urlSortParams);

        it.each(graphQLEnumSortValues)('initial sort is set with value %s', (sort) => {
          wrapper = mountComponent({ provide: { initialSort: sort.toLowerCase() } });

          expect(findIssuableList().props('initialSortBy')).toBe(sort);
        });
      });

      describe('when initial sort value is invalid', () => {
        it.each(['', 'asdf', null, undefined])(
          'initial sort is set to value CREATED_DESC',
          (sort) => {
            wrapper = mountComponent({ provide: { initialSort: sort } });

            expect(findIssuableList().props('initialSortBy')).toBe(CREATED_DESC);
          },
        );
      });

      describe('when sort is manual and issue repositioning is disabled', () => {
        beforeEach(() => {
          wrapper = mountComponent({
            provide: { initialSort: RELATIVE_POSITION, isIssueRepositioningDisabled: true },
          });
        });

        it('changes the sort to the default of created descending', () => {
          expect(findIssuableList().props('initialSortBy')).toBe(CREATED_DESC);
        });

        it('shows an alert to tell the user that manual reordering is disabled', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'Issues are being rebalanced at the moment, so manual reordering is disabled.',
            variant: VARIANT_INFO,
          });
        });
      });
    });

    describe('state', () => {
      it('is set from the url params', () => {
        const initialState = STATUS_ALL;
        setWindowLocation(`?state=${initialState}`);
        getParameterByName.mockImplementation((args) =>
          jest.requireActual('~/lib/utils/url_utility').getParameterByName(args),
        );
        wrapper = mountComponent();

        expect(findIssuableList().props('currentTab')).toBe(initialState);
      });
    });

    describe('filter tokens', () => {
      it('groups url params of assignee and author', () => {
        setWindowLocation(locationSearch);
        wrapper = mountComponent();

        expect(findIssuableList().props('initialFilterValue')).toEqual(groupedFilteredTokens);
      });
    });
  });

  describe('bulk edit', () => {
    describe.each([true, false])(
      'when "issuables:toggleBulkEdit" event is received with payload `%s`',
      (isBulkEdit) => {
        beforeEach(() => {
          wrapper = mountComponent();

          eventHub.$emit('issuables:toggleBulkEdit', isBulkEdit);
        });

        it(`${isBulkEdit ? 'enables' : 'disables'} bulk edit`, () => {
          expect(findIssuableList().props('showBulkEditSidebar')).toBe(isBulkEdit);
        });
      },
    );
  });

  describe('IssuableByEmail component', () => {
    describe.each`
      initialEmail | canCreateIssue | exists
      ${false}     | ${false}       | ${false}
      ${false}     | ${true}        | ${false}
      ${true}      | ${false}       | ${false}
      ${true}      | ${true}        | ${true}
    `(
      `when issue creation by email is enabled=$initialEmail`,
      ({ initialEmail, canCreateIssue, exists }) => {
        it(`${initialEmail ? 'renders' : 'does not render'}`, () => {
          wrapper = mountComponent({ provide: { initialEmail, canCreateIssue } });

          expect(findIssuableByEmail().exists()).toBe(exists);
        });
      },
    );

    it('tracks IssuableByEmail', () => {
      wrapper = mountComponent({ provide: { initialEmail: true, canCreateIssue: true } });

      expect(findIssuableByEmail().attributes()).toMatchObject({
        'data-track-action': 'click_email_issue_project_issues_empty_list_page',
        'data-track-label': 'email_issue_project_issues_empty_list',
      });
    });
  });

  describe('slots', () => {
    describe('empty states', () => {
      describe('when there are issues', () => {
        beforeEach(() => {
          wrapper = mountComponent({
            provide: { hasAnyIssues: true },
            mountFn: mount,
            issuesQueryResponse: jest.fn().mockResolvedValue(getIssuesQueryEmptyResponse),
          });
          return waitForPromises();
        });

        it('shows EmptyStateWithAnyIssues empty state', () => {
          expect(wrapper.findComponent(EmptyStateWithAnyIssues).props()).toEqual({
            hasSearch: false,
            isEpic: false,
            isOpenTab: true,
          });
        });
      });

      describe('when there are no issues', () => {
        beforeEach(() => {
          wrapper = mountComponent({ provide: { hasAnyIssues: false } });
        });

        it('shows EmptyStateWithoutAnyIssues empty state', () => {
          expect(wrapper.findComponent(EmptyStateWithoutAnyIssues).props()).toEqual({
            currentTabCount: 0,
            exportCsvPathWithQuery: defaultProvide.exportCsvPath,
            showCsvButtons: true,
            showIssuableByEmail: false,
            showNewIssueDropdown: false,
          });
        });
      });

      describe('when there are errors', () => {
        beforeEach(() => {
          wrapper = mountComponent({
            provide: { hasAnyIssues: true },
            mountFn: mount,
            issuesQueryResponse: jest.fn().mockRejectedValue(getIssuesQueryEmptyResponse),
          });
          return waitForPromises();
        });

        it('does not show empty state', () => {
          expect(wrapper.findComponent(EmptyStateWithAnyIssues).exists()).toBe(false);
        });
      });
    });

    it('includes IssueCardStatistics component', async () => {
      wrapper = mountComponent();
      await nextTick();
      expect(findIssueCardStatistics().exists()).toBe(true);
    });

    it('includes IssuseCardTimeInfo component', async () => {
      wrapper = mountComponent();
      await nextTick();
      expect(findIssueCardTimeInfo().exists()).toBe(true);
    });
  });

  describe('tokens', () => {
    const mockCurrentUser = {
      id: 1,
      name: 'Administrator',
      username: 'root',
      avatar_url: 'avatar/url',
    };

    describe('when user is signed out', () => {
      beforeEach(() => {
        wrapper = mountComponent({ provide: { isSignedIn: false } });
      });

      it('does not render My-Reaction or Confidential tokens', () => {
        expect(findIssuableList().props('searchTokens')).not.toMatchObject([
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers: [mockCurrentUser] },
          { type: TOKEN_TYPE_ASSIGNEE, preloadedUsers: [mockCurrentUser] },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_CONFIDENTIAL },
        ]);
      });
    });

    describe('when user does not have CRM enabled', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          provide: { canReadCrmContact: false, canReadCrmOrganization: false },
        });
      });

      it('does not render Contact or Organization tokens', () => {
        expect(findIssuableList().props('searchTokens')).not.toMatchObject([
          { type: TOKEN_TYPE_CONTACT },
          { type: TOKEN_TYPE_ORGANIZATION },
        ]);
      });
    });

    describe('when all tokens are available', () => {
      beforeEach(() => {
        window.gon = {
          current_user_id: mockCurrentUser.id,
          current_user_fullname: mockCurrentUser.name,
          current_username: mockCurrentUser.username,
          current_user_avatar_url: mockCurrentUser.avatar_url,
        };

        wrapper = mountComponent({
          provide: {
            canReadCrmContact: true,
            canReadCrmOrganization: true,
            isSignedIn: true,
          },
        });
      });

      it('renders all tokens alphabetically', () => {
        const preloadedUsers = [
          { ...mockCurrentUser, id: convertToGraphQLId(TYPENAME_USER, mockCurrentUser.id) },
        ];

        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_ASSIGNEE, preloadedUsers },
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers },
          { type: TOKEN_TYPE_CLOSED },
          { type: TOKEN_TYPE_CONFIDENTIAL },
          { type: TOKEN_TYPE_CONTACT },
          { type: TOKEN_TYPE_CREATED },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_ORGANIZATION },
          { type: TOKEN_TYPE_RELEASE },
          { type: TOKEN_TYPE_SEARCH_WITHIN },
          { type: TOKEN_TYPE_TYPE },
        ]);
      });
    });
  });

  describe('errors', () => {
    describe.each`
      error                      | mountOption                    | message
      ${'fetching issues'}       | ${'issuesQueryResponse'}       | ${'An error occurred while loading issues'}
      ${'fetching issue counts'} | ${'issuesCountsQueryResponse'} | ${'An error occurred while getting issue counts'}
    `('when there is an error $error', ({ mountOption, message }) => {
      beforeEach(() => {
        wrapper = mountComponent({
          [mountOption]: jest.fn().mockRejectedValue(new Error('ERROR')),
        });
        return waitForPromises();
      });

      it('shows an error message', () => {
        expect(findIssuableList().props('error')).toBe(message);
        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
      });
    });

    it('clears error message when "dismiss-alert" event is emitted from IssuableList', () => {
      wrapper = mountComponent({ issuesQueryResponse: jest.fn().mockRejectedValue(new Error()) });

      findIssuableList().vm.$emit('dismiss-alert');

      expect(findIssuableList().props('error')).toBeNull();
    });
  });

  describe('events', () => {
    describe('when "click-tab" event is emitted by IssuableList', () => {
      beforeEach(async () => {
        wrapper = mountComponent();
        await waitForPromises();
        router.push = jest.fn();

        findIssuableList().vm.$emit('click-tab', STATUS_CLOSED);
      });

      it('updates ui to the new tab', () => {
        expect(findIssuableList().props('currentTab')).toBe(STATUS_CLOSED);
      });

      it('updates url to the new tab', () => {
        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining({ state: STATUS_CLOSED }),
        });
      });
    });

    describe.each`
      event              | params
      ${'next-page'}     | ${{ page_after: 'endcursor', page_before: undefined, first_page_size: 20, last_page_size: undefined }}
      ${'previous-page'} | ${{ page_after: undefined, page_before: 'startcursor', first_page_size: undefined, last_page_size: 20 }}
    `('when "$event" event is emitted by IssuableList', ({ event, params }) => {
      beforeEach(async () => {
        wrapper = mountComponent({
          data: {
            pageInfo: {
              endCursor: 'endCursor',
              startCursor: 'startCursor',
            },
          },
        });
        await waitForPromises();
        router.push = jest.fn();

        findIssuableList().vm.$emit(event);
      });

      it('scrolls to the top', () => {
        expect(scrollUp).toHaveBeenCalled();
      });

      it(`updates url`, () => {
        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining(params),
        });
      });
    });

    describe('when "reorder" event is emitted by IssuableList', () => {
      const issueOne = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/1',
        iid: '101',
        reference: 'group/project#1',
        webPath: '/group/project/-/issues/1',
      };
      const issueTwo = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/2',
        iid: '102',
        reference: 'group/project#2',
        webPath: '/group/project/-/issues/2',
      };
      const issueThree = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/3',
        iid: '103',
        reference: 'group/project#3',
        webPath: '/group/project/-/issues/3',
      };
      const issueFour = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/4',
        iid: '104',
        reference: 'group/project#4',
        webPath: '/group/project/-/issues/4',
      };
      const response = (isProject = true) => ({
        data: {
          [isProject ? 'project' : 'group']: {
            id: '1',
            issues: {
              ...defaultQueryResponse.data.project.issues,
              nodes: [issueOne, issueTwo, issueThree, issueFour],
            },
          },
        },
      });

      describe('when successful', () => {
        describe.each([true, false])('when isProject=%s', (isProject) => {
          describe.each`
            description                       | issueToMove   | oldIndex | newIndex | moveBeforeId    | moveAfterId
            ${'to the beginning of the list'} | ${issueThree} | ${2}     | ${0}     | ${null}         | ${issueOne.id}
            ${'down the list'}                | ${issueOne}   | ${0}     | ${1}     | ${issueTwo.id}  | ${issueThree.id}
            ${'up the list'}                  | ${issueThree} | ${2}     | ${1}     | ${issueOne.id}  | ${issueTwo.id}
            ${'to the end of the list'}       | ${issueTwo}   | ${1}     | ${3}     | ${issueFour.id} | ${null}
          `(
            'when moving issue $description',
            ({ issueToMove, oldIndex, newIndex, moveBeforeId, moveAfterId }) => {
              beforeEach(() => {
                wrapper = mountComponent({
                  provide: { isProject },
                  issuesQueryResponse: jest.fn().mockResolvedValue(response(isProject)),
                });
                return waitForPromises();
              });

              it('makes API call to reorder the issue', async () => {
                findIssuableList().vm.$emit('reorder', { oldIndex, newIndex });
                await waitForPromises();

                expect(axiosMock.history.put[0]).toMatchObject({
                  url: joinPaths(issueToMove.webPath, 'reorder'),
                  data: JSON.stringify({
                    move_before_id: getIdFromGraphQLId(moveBeforeId),
                    move_after_id: getIdFromGraphQLId(moveAfterId),
                  }),
                });
              });
            },
          );
        });
      });

      describe('when unsuccessful', () => {
        beforeEach(() => {
          wrapper = mountComponent({
            issuesQueryResponse: jest.fn().mockResolvedValue(response()),
          });
          return waitForPromises();
        });

        it('displays an error message', async () => {
          axiosMock
            .onPut(joinPaths(issueOne.webPath, 'reorder'))
            .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          findIssuableList().vm.$emit('reorder', { oldIndex: 0, newIndex: 1 });
          await waitForPromises();

          expect(findIssuableList().props('error')).toBe(
            'An error occurred while reordering issues.',
          );
          expect(Sentry.captureException).toHaveBeenCalledWith(
            new Error('Request failed with status code 500'),
          );
        });
      });
    });

    describe('when "sort" event is emitted by IssuableList', () => {
      it.each(Object.keys(urlSortParams))(
        'updates to the new sort when payload is `%s`',
        (sortKey) => {
          // Ensure initial sort key is different so we can trigger an update when emitting a sort key
          wrapper =
            sortKey === CREATED_DESC
              ? mountComponent({ provide: { initialSort: UPDATED_DESC } })
              : mountComponent();
          router.push = jest.fn();

          findIssuableList().vm.$emit('sort', sortKey);

          expect(router.push).toHaveBeenCalledWith({
            query: expect.objectContaining({ sort: urlSortParams[sortKey] }),
          });
        },
      );

      describe('when issue repositioning is disabled', () => {
        const initialSort = CREATED_DESC;

        beforeEach(() => {
          wrapper = mountComponent({
            provide: { initialSort, isIssueRepositioningDisabled: true },
          });
          router.push = jest.fn();

          findIssuableList().vm.$emit('sort', RELATIVE_POSITION_ASC);
        });

        it('does not update the sort to manual', () => {
          expect(router.push).not.toHaveBeenCalled();
        });

        it('shows an alert to tell the user that manual reordering is disabled', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'Issues are being rebalanced at the moment, so manual reordering is disabled.',
            variant: VARIANT_INFO,
          });
        });
      });

      describe('when user is signed in', () => {
        it('calls mutation to save sort preference', () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          wrapper = mountComponent({ sortPreferenceMutationResponse: mutationMock });

          findIssuableList().vm.$emit('sort', UPDATED_DESC);

          expect(mutationMock).toHaveBeenCalledWith({ input: { issuesSort: UPDATED_DESC } });
        });

        it('captures error when mutation response has errors', async () => {
          const mutationMock = jest
            .fn()
            .mockResolvedValue(setSortPreferenceMutationResponseWithErrors);
          wrapper = mountComponent({ sortPreferenceMutationResponse: mutationMock });

          findIssuableList().vm.$emit('sort', UPDATED_DESC);
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
        });
      });

      describe('when user is signed out', () => {
        it('does not call mutation to save sort preference', () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          wrapper = mountComponent({
            provide: { isSignedIn: false },
            sortPreferenceMutationResponse: mutationMock,
          });

          findIssuableList().vm.$emit('sort', CREATED_DESC);

          expect(mutationMock).not.toHaveBeenCalled();
        });
      });
    });

    describe('when "update-legacy-bulk-edit" event is emitted by IssuableList', () => {
      beforeEach(() => {
        wrapper = mountComponent();
        jest.spyOn(eventHub, '$emit');

        findIssuableList().vm.$emit('update-legacy-bulk-edit');
      });

      it('emits an "issuables:updateBulkEdit" event to the legacy bulk edit class', () => {
        expect(eventHub.$emit).toHaveBeenCalledWith('issuables:updateBulkEdit');
      });
    });

    describe('when "filter" event is emitted by IssuableList', () => {
      it('updates IssuableList with url params', async () => {
        wrapper = mountComponent();
        router.push = jest.fn();

        findIssuableList().vm.$emit('filter', filteredTokens);
        await nextTick();

        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining(urlParams),
        });
      });
    });

    describe('when "page-size-change" event is emitted by IssuableList', () => {
      it('updates url params with new page size', async () => {
        wrapper = mountComponent();
        router.push = jest.fn();

        findIssuableList().vm.$emit('page-size-change', 50);
        await nextTick();

        expect(router.push).toHaveBeenCalledTimes(1);
        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining({ first_page_size: 50 }),
        });
      });

      it('calls the query with correct variables', async () => {
        wrapper = mountComponent();

        findIssuableList().vm.$emit('page-size-change', 50);
        await nextTick();

        expect(mockIssuesQueryResponse).toHaveBeenCalledWith(
          expect.objectContaining({
            afterCursor: undefined,
            beforeCursor: undefined,
            firstPageSize: 50,
          }),
        );
      });
    });
  });

  describe('public visibility', () => {
    it.each`
      description                                                                    | isPublicVisibilityRestricted | isSignedIn | hideUsers
      ${'shows users when public visibility is not restricted and is not signed in'} | ${false}                     | ${false}   | ${false}
      ${'shows users when public visibility is not restricted and is signed in'}     | ${false}                     | ${true}    | ${false}
      ${'hides users when public visibility is restricted and is not signed in'}     | ${true}                      | ${false}   | ${true}
      ${'shows users when public visibility is restricted and is signed in'}         | ${true}                      | ${true}    | ${false}
    `('$description', async ({ isPublicVisibilityRestricted, isSignedIn, hideUsers }) => {
      const mockQuery = jest.fn().mockResolvedValue(defaultQueryResponse);
      wrapper = mountComponent({
        provide: { isPublicVisibilityRestricted, isSignedIn },
        issuesQueryResponse: mockQuery,
      });
      await waitForPromises();

      expect(mockQuery).toHaveBeenCalledWith(expect.objectContaining({ hideUsers }));
    });
  });

  describe('fetching issues', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('fetches default work item types', () => {
      const types = [
        WORK_ITEM_TYPE_ENUM_ISSUE,
        WORK_ITEM_TYPE_ENUM_INCIDENT,
        WORK_ITEM_TYPE_ENUM_TASK,
      ];

      expect(mockIssuesQueryResponse).toHaveBeenCalledWith(expect.objectContaining({ types }));
      expect(mockIssuesCountsQueryResponse).toHaveBeenCalledWith(
        expect.objectContaining({ types }),
      );
    });
  });

  describe('when providing token for labels', () => {
    it('passes function to fetchLatestLabels property if frontend caching is enabled', () => {
      wrapper = mountComponent({
        provide: {
          glFeatures: {
            frontendCaching: true,
          },
        },
      });

      expect(typeof findLabelsToken().fetchLatestLabels).toBe('function');
    });

    it('passes null to fetchLatestLabels property if frontend caching is disabled', () => {
      wrapper = mountComponent({
        provide: {
          glFeatures: {
            frontendCaching: false,
          },
        },
      });

      expect(findLabelsToken().fetchLatestLabels).toBe(null);
    });
  });

  describe('when issue drawer is enabled', () => {
    beforeEach(() => {
      wrapper = mountComponent({
        provide: {
          glFeatures: {
            issuesListDrawer: true,
          },
        },
      });
    });

    it('renders issuable drawer component', () => {
      expect(findWorkItemDrawer().exists()).toBe(true);
    });

    it('renders issuable drawer closed by default', () => {
      expect(findWorkItemDrawer().props('open')).toBe(false);
    });

    describe('on selecting an issuable', () => {
      beforeEach(() => {
        findIssuableList().vm.$emit(
          'select-issuable',
          getIssuesQueryResponse.data.project.issues.nodes[0],
        );
        return nextTick();
      });

      it('opens issuable drawer', () => {
        expect(findWorkItemDrawer().props('open')).toBe(true);
      });

      it('selects active issuable', () => {
        expect(findIssuableList().props('activeIssuable')).toEqual(
          getIssuesQueryResponse.data.project.issues.nodes[0],
        );
      });

      describe('when closing the drawer', () => {
        it('closes the drawer on drawer `close` event', async () => {
          findWorkItemDrawer().vm.$emit('close');
          await nextTick();

          expect(findWorkItemDrawer().props('open')).toBe(false);
        });

        it('removes active issuable', async () => {
          findWorkItemDrawer().vm.$emit('close');
          await nextTick();

          expect(findIssuableList().props('activeIssuable')).toBe(null);
        });
      });

      describe('when updating an issuable', () => {
        it('refetches the list if the issuable changed state', async () => {
          const {
            data: { workItem },
          } = workItemResponseFactory({ iid: '789', state: 'CLOSED' });
          findWorkItemDrawer().vm.$emit('work-item-updated', workItem);

          await waitForPromises();

          expect(mockIssuesQueryResponse).toHaveBeenCalledTimes(1);
          expect(mockIssuesCountsQueryResponse).toHaveBeenCalledTimes(1);
        });

        it('updates the assignees field of active issuable', async () => {
          const {
            data: { workItem },
          } = workItemResponseFactory({ id: 'gid://gitlab/WorkItem/123456', iid: '789' });
          findWorkItemDrawer().vm.$emit('work-item-updated', workItem);

          await waitForPromises();

          expect(findIssuableList().props('issuables')[0].assignees.nodes).toEqual(
            mockAssignees.map((assignee) => ({
              ...assignee,
              __persist: true,
            })),
          );
        });

        it('updates the labels field of active issuable', async () => {
          const {
            data: { workItem },
          } = workItemResponseFactory({ id: 'gid://gitlab/WorkItem/123456', iid: '789' });
          findWorkItemDrawer().vm.$emit('work-item-updated', workItem);

          await waitForPromises();

          expect(findIssuableList().props('issuables')[0].labels.nodes).toEqual(
            mockLabels.map((label) => ({
              ...label,
              __persist: true,
              textColor: undefined,
            })),
          );
        });

        it('updates the upvotes count of active issuable', async () => {
          const { workItem } = workItemByIidResponseFactory({
            id: 'gid://gitlab/WorkItem/123456',
            iid: '789',
            awardEmoji: {
              ...mockAwardsWidget,
              nodes: [mockAwardEmojiThumbsUp],
            },
          }).data.workspace;

          findWorkItemDrawer().vm.$emit('work-item-emoji-updated', workItem);

          await waitForPromises();

          expect(findIssuableList().props('issuables')[0].upvotes).toBe(1);
        });

        it('updates the milestone field of active issuable', async () => {
          const {
            data: { workItem },
          } = workItemResponseFactory({ id: 'gid://gitlab/WorkItem/123456', iid: '789' });
          findWorkItemDrawer().vm.$emit('work-item-updated', workItem);

          await waitForPromises();

          expect(findIssuableList().props('issuables')[0].milestone).toEqual({
            ...mockMilestone,
            __persist: true,
            expired: undefined,
            state: undefined,
          });
        });

        it('updates the title and confidential state of active issuable', async () => {
          const {
            data: { workItem },
          } = workItemResponseFactory({
            id: 'gid://gitlab/WorkItem/123456',
            iid: '789',
            confidential: true,
          });
          findWorkItemDrawer().vm.$emit('work-item-updated', workItem);

          await waitForPromises();

          expect(findIssuableList().props('issuables')[0].title).toBe('Updated title');
          expect(findIssuableList().props('issuables')[0].confidential).toBe(true);
        });

        it('refetches the list if new child was added to active issuable', async () => {
          findWorkItemDrawer().vm.$emit('addChild');

          await waitForPromises();

          expect(mockIssuesQueryResponse).toHaveBeenCalledTimes(2);
          expect(mockIssuesCountsQueryResponse).toHaveBeenCalledTimes(2);
        });

        it('updates issuable type to objective if promoted to objective', async () => {
          findWorkItemDrawer().vm.$emit('promotedToObjective', '789');

          await waitForPromises();
          // required for cache updates
          jest.runOnlyPendingTimers();
          await nextTick();

          expect(findIssuableList().props('issuables')[0].type).toBe('OBJECTIVE');
        });
      });

      describe('when deleting an issuable from the drawer', () => {
        beforeEach(() => {
          findWorkItemDrawer().vm.$emit('workItemDeleted');
        });

        it('should refetch issues and issues count', () => {
          expect(mockIssuesQueryResponse).toHaveBeenCalledTimes(2);
          expect(mockIssuesCountsQueryResponse).toHaveBeenCalledTimes(2);
        });

        it('should close the issue drawer', () => {
          expect(findWorkItemDrawer().props('open')).toBe(false);
        });
      });
    });
  });

  it('shows an error when deleting from the drawer fails', async () => {
    wrapper = mountComponent({
      provide: {
        glFeatures: {
          issuesListDrawer: true,
        },
      },
    });

    findIssuableList().vm.$emit(
      'select-issuable',
      getIssuesQueryResponse.data.project.issues.nodes[0],
    );
    await nextTick();

    findWorkItemDrawer().vm.$emit('deleteWorkItemError');
    await nextTick();

    expect(findIssuableList().props('error')).toBe('An error occurred while deleting an issuable.');
  });

  describe('when the URL contains a `show` parameter', () => {
    const { id, iid } = defaultQueryResponse.data.project.issues.nodes[0];
    const mountForShowParameter = async (
      showParams = { id: getIdFromGraphQLId(id), iid, full_path: fullPath },
    ) => {
      const show = btoa(JSON.stringify(showParams));
      setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);
      getParameterByName.mockReturnValue(show);
      wrapper = mountComponent({
        provide: {
          glFeatures: {
            issuesListDrawer: true,
          },
        },
      });
      await waitForPromises();
    };
    it('calls `getParameterByName` to get the `show` param', async () => {
      await mountForShowParameter();

      expect(getParameterByName).toHaveBeenCalledWith(DETAIL_VIEW_QUERY_PARAM_NAME);
    });
    describe('and the `show` param contains an item in the list', () => {
      it('sets the `activeIssuable` for the work item drawer', async () => {
        await mountForShowParameter();

        expect(findWorkItemDrawer().props('activeItem')).toMatchObject({ id, iid, fullPath });
      });
    });
    describe('and the `show` param does not contain an item in the list', () => {
      beforeEach(async () => {
        await mountForShowParameter({
          id: 'gid://gitlab/Issue/999999',
          iid: '999999',
          full_path: 'does/not/match',
        });
      });
      it('`updateHistory` is called', () => {
        expect(updateHistory).toHaveBeenCalled();
      });
      it('`removeParams` is called to remove the `show` param', () => {
        expect(removeParams).toHaveBeenCalledWith([DETAIL_VIEW_QUERY_PARAM_NAME]);
      });
    });
  });

  describe('when the route is updated', () => {
    const { id, iid } = defaultQueryResponse.data.project.issues.nodes[0];
    const show = btoa(JSON.stringify({ id: getIdFromGraphQLId(id), iid, full_path: fullPath }));
    beforeEach(async () => {
      getParameterByName.mockReturnValue(show);
      wrapper = mountComponent({
        provide: {
          glFeatures: {
            issuesListDrawer: true,
          },
        },
      });
      await waitForPromises();
    });
    describe('and the query contains a `show` parameter', () => {
      it('calls `getParameterByName` to get the show param', async () => {
        await router.push({ query: { show } });
        expect(getParameterByName).toHaveBeenLastCalledWith(DETAIL_VIEW_QUERY_PARAM_NAME);
      });
    });
    describe('and the query does not contain a `show` parameter', () => {
      it('sets the `activeIssuable` to null, closing the drawer', async () => {
        findIssuableList().vm.$emit(
          'select-issuable',
          getIssuesQueryResponse.data.project.issues.nodes[0],
        );
        expect(findWorkItemDrawer().props('open')).toBe(true);
        await router.push({ query: { otherThing: true } });
        expect(findWorkItemDrawer().props('open')).toBe(false);
      });
    });
  });
});
