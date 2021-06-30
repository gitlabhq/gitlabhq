import { GlButton, GlEmptyState, GlLink } from '@gitlab/ui';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { cloneDeep } from 'lodash';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import getIssuesQuery from 'ee_else_ce/issues_list/queries/get_issues.query.graphql';
import getIssuesCountQuery from 'ee_else_ce/issues_list/queries/get_issues_count.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import {
  getIssuesQueryResponse,
  filteredTokens,
  locationSearch,
  urlParams,
  getIssuesCountQueryResponse,
} from 'jest/issues_list/mock_data';
import createFlash from '~/flash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/issuable_list/constants';
import IssuesListApp from '~/issues_list/components/issues_list_app.vue';
import {
  CREATED_DESC,
  DUE_DATE_OVERDUE,
  PARAM_DUE_DATE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_WEIGHT,
  urlSortParams,
} from '~/issues_list/constants';
import eventHub from '~/issues_list/eventhub';
import { getSortOptions } from '~/issues_list/utils';
import axios from '~/lib/utils/axios_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { setUrlParams } from '~/lib/utils/url_utility';

jest.mock('~/flash');
jest.mock('~/lib/utils/scroll_utils', () => ({
  scrollUp: jest.fn().mockName('scrollUpMock'),
}));

describe('IssuesListApp component', () => {
  let axiosMock;
  let wrapper;

  const localVue = createLocalVue();
  localVue.use(VueApollo);

  const defaultProvide = {
    calendarPath: 'calendar/path',
    canBulkUpdate: false,
    emptyStateSvgPath: 'empty-state.svg',
    exportCsvPath: 'export/csv/path',
    hasBlockedIssuesFeature: true,
    hasIssueWeightsFeature: true,
    hasIterationsFeature: true,
    hasProjectIssues: true,
    isSignedIn: true,
    issuesPath: 'path/to/issues',
    jiraIntegrationPath: 'jira/integration/path',
    newIssuePath: 'new/issue/path',
    projectPath: 'path/to/project',
    rssPath: 'rss/path',
    showNewIssueLink: true,
    signInPath: 'sign/in/path',
  };

  let defaultQueryResponse = getIssuesQueryResponse;
  if (IS_EE) {
    defaultQueryResponse = cloneDeep(getIssuesQueryResponse);
    defaultQueryResponse.data.project.issues.nodes[0].blockedByCount = 1;
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

  const mountComponent = ({
    provide = {},
    issuesQueryResponse = jest.fn().mockResolvedValue(defaultQueryResponse),
    issuesQueryCountResponse = jest.fn().mockResolvedValue(getIssuesCountQueryResponse),
    mountFn = shallowMount,
  } = {}) => {
    const requestHandlers = [
      [getIssuesQuery, issuesQueryResponse],
      [getIssuesCountQuery, issuesQueryCountResponse],
    ];
    const apolloProvider = createMockApollo(requestHandlers);

    return mountFn(IssuesListApp, {
      localVue,
      apolloProvider,
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    global.jsdom.reconfigure({ url: TEST_HOST });
    axiosMock.reset();
    wrapper.destroy();
  });

  describe('IssuableList', () => {
    beforeEach(() => {
      wrapper = mountComponent();
      jest.runOnlyPendingTimers();
    });

    it('renders', () => {
      expect(findIssuableList().props()).toMatchObject({
        namespace: defaultProvide.projectPath,
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
    it('renders rss button', () => {
      wrapper = mountComponent({ mountFn: mount });

      expect(findGlButtonAt(0).props('icon')).toBe('rss');
      expect(findGlButtonAt(0).attributes()).toMatchObject({
        href: defaultProvide.rssPath,
        'aria-label': IssuesListApp.i18n.rssLabel,
      });
    });

    it('renders calendar button', () => {
      wrapper = mountComponent({ mountFn: mount });

      expect(findGlButtonAt(1).props('icon')).toBe('calendar');
      expect(findGlButtonAt(1).attributes()).toMatchObject({
        href: defaultProvide.calendarPath,
        'aria-label': IssuesListApp.i18n.calendarLabel,
      });
    });

    describe('csv import/export component', () => {
      describe('when user is signed in', () => {
        const search = '?search=refactor&sort=created_date&state=opened';

        beforeEach(() => {
          global.jsdom.reconfigure({ url: `${TEST_HOST}${search}` });

          wrapper = mountComponent({
            provide: { ...defaultProvide, isSignedIn: true },
            mountFn: mount,
          });

          jest.runOnlyPendingTimers();
        });

        it('renders', () => {
          expect(findCsvImportExportButtons().props()).toMatchObject({
            exportCsvPath: `${defaultProvide.exportCsvPath}${search}`,
            issuableCount: 1,
          });
        });
      });

      describe('when user is not signed in', () => {
        it('does not render', () => {
          wrapper = mountComponent({ provide: { ...defaultProvide, isSignedIn: false } });

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
        wrapper = mountComponent({ provide: { canBulkUpdate: false } });

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
        wrapper = mountComponent({ provide: { showNewIssueLink: false } });

        expect(findGlButtons().filter((button) => button.text() === 'New issue')).toHaveLength(0);
      });
    });
  });

  describe('initial url params', () => {
    describe('due_date', () => {
      it('is set from the url params', () => {
        global.jsdom.reconfigure({ url: `${TEST_HOST}?${PARAM_DUE_DATE}=${DUE_DATE_OVERDUE}` });

        wrapper = mountComponent();

        expect(findIssuableList().props('urlParams')).toMatchObject({ due_date: DUE_DATE_OVERDUE });
      });
    });

    describe('search', () => {
      it('is set from the url params', () => {
        global.jsdom.reconfigure({ url: `${TEST_HOST}${locationSearch}` });

        wrapper = mountComponent();

        expect(findIssuableList().props('urlParams')).toMatchObject({ search: 'find issues' });
      });
    });

    describe('sort', () => {
      it.each(Object.keys(urlSortParams))('is set as %s from the url params', (sortKey) => {
        global.jsdom.reconfigure({
          url: setUrlParams({ sort: urlSortParams[sortKey] }, TEST_HOST),
        });

        wrapper = mountComponent();

        expect(findIssuableList().props()).toMatchObject({
          initialSortBy: sortKey,
          urlParams: {
            sort: urlSortParams[sortKey],
          },
        });
      });
    });

    describe('state', () => {
      it('is set from the url params', () => {
        const initialState = IssuableStates.All;

        global.jsdom.reconfigure({ url: setUrlParams({ state: initialState }, TEST_HOST) });

        wrapper = mountComponent();

        expect(findIssuableList().props('currentTab')).toBe(initialState);
      });
    });

    describe('filter tokens', () => {
      it('is set from the url params', () => {
        global.jsdom.reconfigure({ url: `${TEST_HOST}${locationSearch}` });

        wrapper = mountComponent();

        expect(findIssuableList().props('initialFilterValue')).toEqual(filteredTokens);
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
          global.jsdom.reconfigure({ url: `${TEST_HOST}?search=no+results` });

          wrapper = mountComponent({ provide: { hasProjectIssues: true }, mountFn: mount });
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
          wrapper = mountComponent({ provide: { hasProjectIssues: true }, mountFn: mount });
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
          global.jsdom.reconfigure({
            url: setUrlParams({ state: IssuableStates.Closed }, TEST_HOST),
          });

          wrapper = mountComponent({ provide: { hasProjectIssues: true }, mountFn: mount });
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
            provide: { hasProjectIssues: false, isSignedIn: true },
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
            provide: { hasProjectIssues: false, isSignedIn: false },
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
        wrapper = mountComponent({
          provide: {
            isSignedIn: false,
          },
        });
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

    describe('when iterations are not available', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          provide: {
            projectIterationsPath: '',
          },
        });
      });

      it('does not render Iteration token', () => {
        expect(findIssuableList().props('searchTokens')).not.toMatchObject([
          { type: TOKEN_TYPE_ITERATION },
        ]);
      });
    });

    describe('when epics are not available', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          provide: {
            groupEpicsPath: '',
          },
        });
      });

      it('does not render Epic token', () => {
        expect(findIssuableList().props('searchTokens')).not.toMatchObject([
          { type: TOKEN_TYPE_EPIC },
        ]);
      });
    });

    describe('when weights are not available', () => {
      beforeEach(() => {
        wrapper = mountComponent({
          provide: {
            groupEpicsPath: '',
          },
        });
      });

      it('does not render Weight token', () => {
        expect(findIssuableList().props('searchTokens')).not.toMatchObject([
          { type: TOKEN_TYPE_WEIGHT },
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

        wrapper = mountComponent({
          provide: {
            isSignedIn: true,
            projectIterationsPath: 'project/iterations/path',
            groupEpicsPath: 'group/epics/path',
            hasIssueWeightsFeature: true,
          },
        });
      });

      it('renders all tokens', () => {
        const preloadedAuthors = [
          { ...mockCurrentUser, id: convertToGraphQLId('User', mockCurrentUser.id) },
        ];

        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_AUTHOR, preloadedAuthors },
          { type: TOKEN_TYPE_ASSIGNEE, preloadedAuthors },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_CONFIDENTIAL },
          { type: TOKEN_TYPE_ITERATION },
          { type: TOKEN_TYPE_EPIC },
          { type: TOKEN_TYPE_WEIGHT },
        ]);
      });
    });
  });

  describe('errors', () => {
    describe.each`
      error                      | mountOption                   | message
      ${'fetching issues'}       | ${'issuesQueryResponse'}      | ${IssuesListApp.i18n.errorFetchingIssues}
      ${'fetching issue counts'} | ${'issuesQueryCountResponse'} | ${IssuesListApp.i18n.errorFetchingCounts}
    `('when there is an error $error', ({ mountOption, message }) => {
      beforeEach(() => {
        wrapper = mountComponent({
          [mountOption]: jest.fn().mockRejectedValue(new Error('ERROR')),
        });
        jest.runOnlyPendingTimers();
      });

      it('shows an error message', () => {
        expect(createFlash).toHaveBeenCalledWith({
          captureError: true,
          error: new Error('Network error: ERROR'),
          message,
        });
      });
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
        iid: 101,
        title: 'Issue one',
      };
      const issueTwo = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/2',
        iid: 102,
        title: 'Issue two',
      };
      const issueThree = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/3',
        iid: 103,
        title: 'Issue three',
      };
      const issueFour = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/4',
        iid: 104,
        title: 'Issue four',
      };
      const response = {
        data: {
          project: {
            issues: {
              ...defaultQueryResponse.data.project.issues,
              nodes: [issueOne, issueTwo, issueThree, issueFour],
            },
          },
        },
      };

      beforeEach(() => {
        wrapper = mountComponent({ issuesQueryResponse: jest.fn().mockResolvedValue(response) });
        jest.runOnlyPendingTimers();
      });

      describe('when unsuccessful', () => {
        it('displays an error message', async () => {
          axiosMock.onPut(`${defaultProvide.issuesPath}/${issueOne.iid}/reorder`).reply(500);

          findIssuableList().vm.$emit('reorder', { oldIndex: 0, newIndex: 1 });

          await waitForPromises();

          expect(createFlash).toHaveBeenCalledWith({ message: IssuesListApp.i18n.reorderError });
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
      beforeEach(() => {
        wrapper = mountComponent();

        findIssuableList().vm.$emit('filter', filteredTokens);
      });

      it('updates IssuableList with url params', () => {
        expect(findIssuableList().props('urlParams')).toMatchObject(urlParams);
      });
    });
  });
});
