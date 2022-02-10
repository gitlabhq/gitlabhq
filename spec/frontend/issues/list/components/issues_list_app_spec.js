import { GlButton, GlEmptyState, GlLink } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { mount, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { cloneDeep } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import getIssuesCountsQuery from 'ee_else_ce/issues/list/queries/get_issues_counts.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import {
  getIssuesCountsQueryResponse,
  getIssuesQueryResponse,
  filteredTokens,
  locationSearch,
  setSortPreferenceMutationResponse,
  setSortPreferenceMutationResponseWithErrors,
  urlParams,
} from 'jest/issues/list/mock_data';
import createFlash, { FLASH_TYPES } from '~/flash';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/vue_shared/issuable/list/constants';
import IssuesListApp from '~/issues/list/components/issues_list_app.vue';
import NewIssueDropdown from '~/issues/list/components/new_issue_dropdown.vue';
import {
  CREATED_DESC,
  RELATIVE_POSITION,
  RELATIVE_POSITION_ASC,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  urlSortParams,
} from '~/issues/list/constants';
import eventHub from '~/issues/list/eventhub';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { getSortKey, getSortOptions } from '~/issues/list/utils';
import axios from '~/lib/utils/axios_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { joinPaths } from '~/lib/utils/url_utility';

jest.mock('@sentry/browser');
jest.mock('~/flash');
jest.mock('~/lib/utils/scroll_utils', () => ({ scrollUp: jest.fn() }));

describe('CE IssuesListApp component', () => {
  let axiosMock;
  let wrapper;

  Vue.use(VueApollo);

  const defaultProvide = {
    autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
    calendarPath: 'calendar/path',
    canBulkUpdate: false,
    emptyStateSvgPath: 'empty-state.svg',
    exportCsvPath: 'export/csv/path',
    fullPath: 'path/to/project',
    hasAnyIssues: true,
    hasAnyProjects: true,
    hasBlockedIssuesFeature: true,
    hasIssuableHealthStatusFeature: true,
    hasIssueWeightsFeature: true,
    hasIterationsFeature: true,
    hasMultipleIssueAssigneesFeature: true,
    initialEmail: 'email@example.com',
    initialSort: CREATED_DESC,
    isAnonymousSearchDisabled: false,
    isIssueRepositioningDisabled: false,
    isProject: true,
    isSignedIn: true,
    jiraIntegrationPath: 'jira/integration/path',
    newIssuePath: 'new/issue/path',
    releasesPath: 'releases/path',
    rssPath: 'rss/path',
    showNewIssueLink: true,
    signInPath: 'sign/in/path',
  };

  let defaultQueryResponse = getIssuesQueryResponse;
  if (IS_EE) {
    defaultQueryResponse = cloneDeep(getIssuesQueryResponse);
    defaultQueryResponse.data.project.issues.nodes[0].blockingCount = 1;
    defaultQueryResponse.data.project.issues.nodes[0].healthStatus = null;
    defaultQueryResponse.data.project.issues.nodes[0].weight = 5;
  }

  const findCsvImportExportButtons = () => wrapper.findComponent(CsvImportExportButtons);
  const findIssuableByEmail = () => wrapper.findComponent(IssuableByEmail);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlButtons = () => wrapper.findAllComponents(GlButton);
  const findGlButtonAt = (index) => findGlButtons().at(index);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findNewIssueDropdown = () => wrapper.findComponent(NewIssueDropdown);

  const mountComponent = ({
    provide = {},
    issuesQueryResponse = jest.fn().mockResolvedValue(defaultQueryResponse),
    issuesCountsQueryResponse = jest.fn().mockResolvedValue(getIssuesCountsQueryResponse),
    sortPreferenceMutationResponse = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse),
    mountFn = shallowMount,
  } = {}) => {
    const requestHandlers = [
      [getIssuesQuery, issuesQueryResponse],
      [getIssuesCountsQuery, issuesCountsQueryResponse],
      [setSortPreferenceMutation, sortPreferenceMutationResponse],
    ];
    const apolloProvider = createMockApollo(requestHandlers);

    return mountFn(IssuesListApp, {
      apolloProvider,
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    setWindowLocation(TEST_HOST);
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
    wrapper.destroy();
  });

  describe('IssuableList', () => {
    beforeEach(async () => {
      wrapper = mountComponent();
      jest.runOnlyPendingTimers();
      await waitForPromises();
    });

    it('renders', () => {
      expect(findIssuableList().props()).toMatchObject({
        namespace: defaultProvide.fullPath,
        recentSearchesStorageKey: 'issues',
        searchInputPlaceholder: IssuesListApp.i18n.searchPlaceholder,
        sortOptions: getSortOptions(true, true),
        initialSortBy: CREATED_DESC,
        issuables: getIssuesQueryResponse.data.project.issues.nodes,
        tabs: IssuableListTabs,
        currentTab: IssuableStates.Opened,
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
        urlParams: {
          sort: urlSortParams[CREATED_DESC],
          state: IssuableStates.Opened,
        },
      });
    });
  });

  describe('header action buttons', () => {
    it('renders rss button', async () => {
      wrapper = mountComponent({ mountFn: mount });
      await waitForPromises();

      expect(findGlButtonAt(0).props('icon')).toBe('rss');
      expect(findGlButtonAt(0).attributes()).toMatchObject({
        href: defaultProvide.rssPath,
        'aria-label': IssuesListApp.i18n.rssLabel,
      });
    });

    it('renders calendar button', async () => {
      wrapper = mountComponent({ mountFn: mount });
      await waitForPromises();

      expect(findGlButtonAt(1).props('icon')).toBe('calendar');
      expect(findGlButtonAt(1).attributes()).toMatchObject({
        href: defaultProvide.calendarPath,
        'aria-label': IssuesListApp.i18n.calendarLabel,
      });
    });

    describe('csv import/export component', () => {
      describe('when user is signed in', () => {
        beforeEach(async () => {
          setWindowLocation('?search=refactor&state=opened');

          wrapper = mountComponent({
            provide: { initialSortBy: CREATED_DESC, isSignedIn: true },
            mountFn: mount,
          });

          jest.runOnlyPendingTimers();
          await waitForPromises();
        });

        it('renders', () => {
          expect(findCsvImportExportButtons().props()).toMatchObject({
            exportCsvPath: `${defaultProvide.exportCsvPath}?search=refactor&sort=created_date&state=opened`,
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

    describe('bulk edit button', () => {
      it('renders when user has permissions', () => {
        wrapper = mountComponent({ provide: { canBulkUpdate: true }, mountFn: mount });

        expect(findGlButtonAt(2).text()).toBe('Edit issues');
      });

      it('does not render when user does not have permissions', () => {
        wrapper = mountComponent({ provide: { canBulkUpdate: false }, mountFn: mount });

        expect(findGlButtons().filter((button) => button.text() === 'Edit issues')).toHaveLength(0);
      });

      it('emits "issuables:enableBulkEdit" event to legacy bulk edit class', async () => {
        wrapper = mountComponent({ provide: { canBulkUpdate: true }, mountFn: mount });

        jest.spyOn(eventHub, '$emit');

        findGlButtonAt(2).vm.$emit('click');

        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith('issuables:enableBulkEdit');
      });
    });

    describe('new issue button', () => {
      it('renders when user has permissions', () => {
        wrapper = mountComponent({ provide: { showNewIssueLink: true }, mountFn: mount });

        expect(findGlButtonAt(2).text()).toBe('New issue');
        expect(findGlButtonAt(2).attributes('href')).toBe(defaultProvide.newIssuePath);
      });

      it('does not render when user does not have permissions', () => {
        wrapper = mountComponent({ provide: { showNewIssueLink: false }, mountFn: mount });

        expect(findGlButtons().filter((button) => button.text() === 'New issue')).toHaveLength(0);
      });
    });

    describe('new issue split dropdown', () => {
      it('does not render in a project context', () => {
        wrapper = mountComponent({ provide: { isProject: true }, mountFn: mount });

        expect(findNewIssueDropdown().exists()).toBe(false);
      });

      it('renders in a group context', () => {
        wrapper = mountComponent({ provide: { isProject: false }, mountFn: mount });

        expect(findNewIssueDropdown().exists()).toBe(true);
      });
    });
  });

  describe('initial url params', () => {
    describe('search', () => {
      it('is set from the url params', () => {
        setWindowLocation(locationSearch);

        wrapper = mountComponent();

        expect(findIssuableList().props('urlParams')).toMatchObject({ search: 'find issues' });
      });
    });

    describe('sort', () => {
      describe('when initial sort value uses old enum values', () => {
        const oldEnumSortValues = Object.values(urlSortParams);

        it.each(oldEnumSortValues)('initial sort is set with value %s', (sort) => {
          wrapper = mountComponent({ provide: { initialSort: sort } });

          expect(findIssuableList().props()).toMatchObject({
            initialSortBy: getSortKey(sort),
            urlParams: { sort },
          });
        });
      });

      describe('when initial sort value uses new GraphQL enum values', () => {
        const graphQLEnumSortValues = Object.keys(urlSortParams);

        it.each(graphQLEnumSortValues)('initial sort is set with value %s', (sort) => {
          wrapper = mountComponent({ provide: { initialSort: sort.toLowerCase() } });

          expect(findIssuableList().props()).toMatchObject({
            initialSortBy: sort,
            urlParams: { sort: urlSortParams[sort] },
          });
        });
      });

      describe('when initial sort value is invalid', () => {
        it.each(['', 'asdf', null, undefined])(
          'initial sort is set to value CREATED_DESC',
          (sort) => {
            wrapper = mountComponent({ provide: { initialSort: sort } });

            expect(findIssuableList().props()).toMatchObject({
              initialSortBy: CREATED_DESC,
              urlParams: { sort: urlSortParams[CREATED_DESC] },
            });
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
          expect(findIssuableList().props()).toMatchObject({
            initialSortBy: CREATED_DESC,
            urlParams: { sort: urlSortParams[CREATED_DESC] },
          });
        });

        it('shows an alert to tell the user that manual reordering is disabled', () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: IssuesListApp.i18n.issueRepositioningMessage,
            type: FLASH_TYPES.NOTICE,
          });
        });
      });
    });

    describe('state', () => {
      it('is set from the url params', () => {
        const initialState = IssuableStates.All;

        setWindowLocation(`?state=${initialState}`);

        wrapper = mountComponent();

        expect(findIssuableList().props('currentTab')).toBe(initialState);
      });
    });

    describe('filter tokens', () => {
      it('is set from the url params', () => {
        setWindowLocation(locationSearch);

        wrapper = mountComponent();

        expect(findIssuableList().props('initialFilterValue')).toEqual(filteredTokens);
      });

      describe('when anonymous searching is performed', () => {
        beforeEach(() => {
          setWindowLocation(locationSearch);

          wrapper = mountComponent({
            provide: { isAnonymousSearchDisabled: true, isSignedIn: false },
          });
        });

        it('is not set from url params', () => {
          expect(findIssuableList().props('initialFilterValue')).toEqual([]);
        });

        it('shows an alert to tell the user they must be signed in to search', () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: IssuesListApp.i18n.anonymousSearchingMessage,
            type: FLASH_TYPES.NOTICE,
          });
        });
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
    describe.each([true, false])(`when issue creation by email is enabled=%s`, (enabled) => {
      it(`${enabled ? 'renders' : 'does not render'}`, () => {
        wrapper = mountComponent({ provide: { initialEmail: enabled } });

        expect(findIssuableByEmail().exists()).toBe(enabled);
      });
    });
  });

  describe('empty states', () => {
    describe('when there are issues', () => {
      describe('when search returns no results', () => {
        beforeEach(() => {
          setWindowLocation(`?search=no+results`);

          wrapper = mountComponent({ provide: { hasAnyIssues: true }, mountFn: mount });
        });

        it('shows empty state', () => {
          expect(findGlEmptyState().props()).toMatchObject({
            description: IssuesListApp.i18n.noSearchResultsDescription,
            title: IssuesListApp.i18n.noSearchResultsTitle,
            svgPath: defaultProvide.emptyStateSvgPath,
          });
        });
      });

      describe('when "Open" tab has no issues', () => {
        beforeEach(() => {
          wrapper = mountComponent({ provide: { hasAnyIssues: true }, mountFn: mount });
        });

        it('shows empty state', () => {
          expect(findGlEmptyState().props()).toMatchObject({
            description: IssuesListApp.i18n.noOpenIssuesDescription,
            title: IssuesListApp.i18n.noOpenIssuesTitle,
            svgPath: defaultProvide.emptyStateSvgPath,
          });
        });
      });

      describe('when "Closed" tab has no issues', () => {
        beforeEach(() => {
          setWindowLocation(`?state=${IssuableStates.Closed}`);

          wrapper = mountComponent({ provide: { hasAnyIssues: true }, mountFn: mount });
        });

        it('shows empty state', () => {
          expect(findGlEmptyState().props()).toMatchObject({
            title: IssuesListApp.i18n.noClosedIssuesTitle,
            svgPath: defaultProvide.emptyStateSvgPath,
          });
        });
      });
    });

    describe('when there are no issues', () => {
      describe('when user is logged in', () => {
        beforeEach(() => {
          wrapper = mountComponent({
            provide: { hasAnyIssues: false, isSignedIn: true },
            mountFn: mount,
          });
        });

        it('shows empty state', () => {
          expect(findGlEmptyState().props()).toMatchObject({
            description: IssuesListApp.i18n.noIssuesSignedInDescription,
            title: IssuesListApp.i18n.noIssuesSignedInTitle,
            svgPath: defaultProvide.emptyStateSvgPath,
          });
        });

        it('shows "New issue" and import/export buttons', () => {
          expect(findGlButton().text()).toBe(IssuesListApp.i18n.newIssueLabel);
          expect(findGlButton().attributes('href')).toBe(defaultProvide.newIssuePath);
          expect(findCsvImportExportButtons().props()).toMatchObject({
            exportCsvPath: defaultProvide.exportCsvPath,
            issuableCount: 0,
          });
        });

        it('shows Jira integration information', () => {
          const paragraphs = wrapper.findAll('p');
          expect(paragraphs.at(1).text()).toContain(IssuesListApp.i18n.jiraIntegrationTitle);
          expect(paragraphs.at(2).text()).toContain(
            'Enable the Jira integration to view your Jira issues in GitLab.',
          );
          expect(paragraphs.at(3).text()).toContain(
            IssuesListApp.i18n.jiraIntegrationSecondaryMessage,
          );
          expect(findGlLink().text()).toBe('Enable the Jira integration');
          expect(findGlLink().attributes('href')).toBe(defaultProvide.jiraIntegrationPath);
        });
      });

      describe('when user is logged out', () => {
        beforeEach(() => {
          wrapper = mountComponent({
            provide: { hasAnyIssues: false, isSignedIn: false },
          });
        });

        it('shows empty state', () => {
          expect(findGlEmptyState().props()).toMatchObject({
            description: IssuesListApp.i18n.noIssuesSignedOutDescription,
            title: IssuesListApp.i18n.noIssuesSignedOutTitle,
            svgPath: defaultProvide.emptyStateSvgPath,
            primaryButtonText: IssuesListApp.i18n.noIssuesSignedOutButtonText,
            primaryButtonLink: defaultProvide.signInPath,
          });
        });
      });
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
          { type: TOKEN_TYPE_AUTHOR, preloadedAuthors: [mockCurrentUser] },
          { type: TOKEN_TYPE_ASSIGNEE, preloadedAuthors: [mockCurrentUser] },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_CONFIDENTIAL },
        ]);
      });
    });

    describe('when all tokens are available', () => {
      const originalGon = window.gon;

      beforeEach(() => {
        window.gon = {
          ...originalGon,
          current_user_id: mockCurrentUser.id,
          current_user_fullname: mockCurrentUser.name,
          current_username: mockCurrentUser.username,
          current_user_avatar_url: mockCurrentUser.avatar_url,
        };

        wrapper = mountComponent({ provide: { isSignedIn: true } });
      });

      afterEach(() => {
        window.gon = originalGon;
      });

      it('renders all tokens alphabetically', () => {
        const preloadedAuthors = [
          { ...mockCurrentUser, id: convertToGraphQLId('User', mockCurrentUser.id) },
        ];

        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_ASSIGNEE, preloadedAuthors },
          { type: TOKEN_TYPE_AUTHOR, preloadedAuthors },
          { type: TOKEN_TYPE_CONFIDENTIAL },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_RELEASE },
          { type: TOKEN_TYPE_TYPE },
        ]);
      });
    });
  });

  describe('errors', () => {
    describe.each`
      error                      | mountOption                    | message
      ${'fetching issues'}       | ${'issuesQueryResponse'}       | ${IssuesListApp.i18n.errorFetchingIssues}
      ${'fetching issue counts'} | ${'issuesCountsQueryResponse'} | ${IssuesListApp.i18n.errorFetchingCounts}
    `('when there is an error $error', ({ mountOption, message }) => {
      beforeEach(async () => {
        wrapper = mountComponent({
          [mountOption]: jest.fn().mockRejectedValue(new Error('ERROR')),
        });
        jest.runOnlyPendingTimers();
        await waitForPromises();
      });

      it('shows an error message', () => {
        expect(findIssuableList().props('error')).toBe(message);
        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('Network error: ERROR'));
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
      beforeEach(() => {
        wrapper = mountComponent();

        findIssuableList().vm.$emit('click-tab', IssuableStates.Closed);
      });

      it('updates to the new tab', () => {
        expect(findIssuableList().props('currentTab')).toBe(IssuableStates.Closed);
      });
    });

    describe.each(['next-page', 'previous-page'])(
      'when "%s" event is emitted by IssuableList',
      (event) => {
        beforeEach(() => {
          wrapper = mountComponent();

          findIssuableList().vm.$emit(event);
        });

        it('scrolls to the top', () => {
          expect(scrollUp).toHaveBeenCalled();
        });
      },
    );

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
                jest.runOnlyPendingTimers();
              });

              it('makes API call to reorder the issue', async () => {
                findIssuableList().vm.$emit('reorder', { oldIndex, newIndex });

                await waitForPromises();

                expect(axiosMock.history.put[0]).toMatchObject({
                  url: joinPaths(issueToMove.webPath, 'reorder'),
                  data: JSON.stringify({
                    move_before_id: getIdFromGraphQLId(moveBeforeId),
                    move_after_id: getIdFromGraphQLId(moveAfterId),
                    group_full_path: isProject ? undefined : defaultProvide.fullPath,
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
          jest.runOnlyPendingTimers();
        });

        it('displays an error message', async () => {
          axiosMock.onPut(joinPaths(issueOne.webPath, 'reorder')).reply(500);

          findIssuableList().vm.$emit('reorder', { oldIndex: 0, newIndex: 1 });

          await waitForPromises();

          expect(findIssuableList().props('error')).toBe(IssuesListApp.i18n.reorderError);
          expect(Sentry.captureException).toHaveBeenCalledWith(
            new Error('Request failed with status code 500'),
          );
        });
      });
    });

    describe('when "sort" event is emitted by IssuableList', () => {
      it.each(Object.keys(urlSortParams))(
        'updates to the new sort when payload is `%s`',
        async (sortKey) => {
          wrapper = mountComponent();

          findIssuableList().vm.$emit('sort', sortKey);

          jest.runOnlyPendingTimers();
          await nextTick();

          expect(findIssuableList().props('urlParams')).toMatchObject({
            sort: urlSortParams[sortKey],
          });
        },
      );

      describe('when issue repositioning is disabled', () => {
        const initialSort = CREATED_DESC;

        beforeEach(() => {
          wrapper = mountComponent({
            provide: { initialSort, isIssueRepositioningDisabled: true },
          });

          findIssuableList().vm.$emit('sort', RELATIVE_POSITION_ASC);
        });

        it('does not update the sort to manual', () => {
          expect(findIssuableList().props('urlParams')).toMatchObject({
            sort: urlSortParams[initialSort],
          });
        });

        it('shows an alert to tell the user that manual reordering is disabled', () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: IssuesListApp.i18n.issueRepositioningMessage,
            type: FLASH_TYPES.NOTICE,
          });
        });
      });

      describe('when user is signed in', () => {
        it('calls mutation to save sort preference', () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          wrapper = mountComponent({ sortPreferenceMutationResponse: mutationMock });

          findIssuableList().vm.$emit('sort', CREATED_DESC);

          expect(mutationMock).toHaveBeenCalledWith({ input: { issuesSort: CREATED_DESC } });
        });

        it('captures error when mutation response has errors', async () => {
          const mutationMock = jest
            .fn()
            .mockResolvedValue(setSortPreferenceMutationResponseWithErrors);
          wrapper = mountComponent({ sortPreferenceMutationResponse: mutationMock });

          findIssuableList().vm.$emit('sort', CREATED_DESC);
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

        findIssuableList().vm.$emit('filter', filteredTokens);
        await nextTick();

        expect(findIssuableList().props('urlParams')).toMatchObject(urlParams);
      });

      describe('when anonymous searching is performed', () => {
        beforeEach(() => {
          wrapper = mountComponent({
            provide: { isAnonymousSearchDisabled: true, isSignedIn: false },
          });

          findIssuableList().vm.$emit('filter', filteredTokens);
        });

        it('does not update IssuableList with url params ', async () => {
          const defaultParams = { sort: 'created_date', state: 'opened' };

          expect(findIssuableList().props('urlParams')).toEqual(defaultParams);
        });

        it('shows an alert to tell the user they must be signed in to search', () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: IssuesListApp.i18n.anonymousSearchingMessage,
            type: FLASH_TYPES.NOTICE,
          });
        });
      });
    });
  });
});
