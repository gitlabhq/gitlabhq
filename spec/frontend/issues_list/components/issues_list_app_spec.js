import { GlButton, GlEmptyState, GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { apiParams, filteredTokens, locationSearch, urlParams } from 'jest/issues_list/mock_data';
import createFlash from '~/flash';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/issuable_list/constants';
import IssuesListApp from '~/issues_list/components/issues_list_app.vue';
import {
  apiSortParams,
  CREATED_DESC,
  DUE_DATE_OVERDUE,
  PAGE_SIZE,
  PAGE_SIZE_MANUAL,
  PARAM_DUE_DATE,
  RELATIVE_POSITION_DESC,
  urlSortParams,
} from '~/issues_list/constants';
import eventHub from '~/issues_list/eventhub';
import { getSortOptions } from '~/issues_list/utils';
import axios from '~/lib/utils/axios_utils';
import { setUrlParams } from '~/lib/utils/url_utility';

jest.mock('~/flash');

describe('IssuesListApp component', () => {
  let axiosMock;
  let wrapper;

  const defaultProvide = {
    autocompleteUsersPath: 'autocomplete/users/path',
    calendarPath: 'calendar/path',
    canBulkUpdate: false,
    emptyStateSvgPath: 'empty-state.svg',
    endpoint: 'api/endpoint',
    exportCsvPath: 'export/csv/path',
    hasBlockedIssuesFeature: true,
    hasIssues: true,
    hasIssueWeightsFeature: true,
    isSignedIn: false,
    issuesPath: 'path/to/issues',
    jiraIntegrationPath: 'jira/integration/path',
    newIssuePath: 'new/issue/path',
    projectLabelsPath: 'project/labels/path',
    projectPath: 'path/to/project',
    rssPath: 'rss/path',
    showNewIssueLink: true,
    signInPath: 'sign/in/path',
  };

  const state = 'opened';
  const xPage = 1;
  const xTotal = 25;
  const tabCounts = {
    opened: xTotal,
    closed: undefined,
    all: undefined,
  };
  const fetchIssuesResponse = {
    data: [],
    headers: {
      'x-page': xPage,
      'x-total': xTotal,
    },
  };

  const findCsvImportExportButtons = () => wrapper.findComponent(CsvImportExportButtons);
  const findIssuableByEmail = () => wrapper.findComponent(IssuableByEmail);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlButtons = () => wrapper.findAllComponents(GlButton);
  const findGlButtonAt = (index) => findGlButtons().at(index);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findIssuableList = () => wrapper.findComponent(IssuableList);

  const mountComponent = ({ provide = {}, mountFn = shallowMount } = {}) =>
    mountFn(IssuesListApp, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock
      .onGet(defaultProvide.endpoint)
      .reply(200, fetchIssuesResponse.data, fetchIssuesResponse.headers);
  });

  afterEach(() => {
    global.jsdom.reconfigure({ url: TEST_HOST });
    axiosMock.reset();
    wrapper.destroy();
  });

  describe('IssuableList', () => {
    beforeEach(async () => {
      wrapper = mountComponent();
      await waitForPromises();
    });

    it('renders', () => {
      expect(findIssuableList().props()).toMatchObject({
        namespace: defaultProvide.projectPath,
        recentSearchesStorageKey: 'issues',
        searchInputPlaceholder: 'Search or filter results…',
        sortOptions: getSortOptions(true, true),
        initialSortBy: CREATED_DESC,
        tabs: IssuableListTabs,
        currentTab: IssuableStates.Opened,
        tabCounts,
        showPaginationControls: false,
        issuables: [],
        totalItems: xTotal,
        currentPage: xPage,
        previousPage: xPage - 1,
        nextPage: xPage + 1,
        urlParams: { page: xPage, state },
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
        it('renders', async () => {
          const search = '?page=1&search=refactor&state=opened&sort=created_date';

          global.jsdom.reconfigure({ url: `${TEST_HOST}${search}` });

          wrapper = mountComponent({
            provide: { ...defaultProvide, isSignedIn: true },
            mountFn: mount,
          });

          await waitForPromises();

          expect(findCsvImportExportButtons().props()).toMatchObject({
            exportCsvPath: `${defaultProvide.exportCsvPath}${search}`,
            issuableCount: xTotal,
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

    describe('page', () => {
      it('is set from the url params', () => {
        const page = 5;

        global.jsdom.reconfigure({ url: setUrlParams({ page }, TEST_HOST) });

        wrapper = mountComponent();

        expect(findIssuableList().props('currentPage')).toBe(page);
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
        global.jsdom.reconfigure({ url: setUrlParams(urlSortParams[sortKey], TEST_HOST) });

        wrapper = mountComponent();

        expect(findIssuableList().props()).toMatchObject({
          initialSortBy: sortKey,
          urlParams: urlSortParams[sortKey],
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
        beforeEach(async () => {
          global.jsdom.reconfigure({ url: `${TEST_HOST}?search=no+results` });

          wrapper = mountComponent({ provide: { hasIssues: true }, mountFn: mount });

          await waitForPromises();
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
        beforeEach(async () => {
          wrapper = mountComponent({ provide: { hasIssues: true }, mountFn: mount });

          await waitForPromises();
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
        beforeEach(async () => {
          global.jsdom.reconfigure({
            url: setUrlParams({ state: IssuableStates.Closed }, TEST_HOST),
          });

          wrapper = mountComponent({ provide: { hasIssues: true }, mountFn: mount });

          await waitForPromises();
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
            provide: { hasIssues: false, isSignedIn: true },
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
            provide: { hasIssues: false, isSignedIn: false },
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

  describe('events', () => {
    describe('when "click-tab" event is emitted by IssuableList', () => {
      beforeEach(() => {
        axiosMock.onGet(defaultProvide.endpoint).reply(200, fetchIssuesResponse.data, {
          'x-page': 2,
          'x-total': xTotal,
        });

        wrapper = mountComponent();

        findIssuableList().vm.$emit('click-tab', IssuableStates.Closed);
      });

      it('makes API call to filter the list by the new state and resets the page to 1', () => {
        expect(axiosMock.history.get[1].params).toMatchObject({
          page: 1,
          state: IssuableStates.Closed,
        });
      });
    });

    describe('when "page-change" event is emitted by IssuableList', () => {
      const data = [{ id: 10, title: 'title', state }];
      const page = 2;
      const totalItems = 21;

      beforeEach(async () => {
        axiosMock.onGet(defaultProvide.endpoint).reply(200, data, {
          'x-page': page,
          'x-total': totalItems,
        });

        wrapper = mountComponent();

        findIssuableList().vm.$emit('page-change', page);

        await waitForPromises();
      });

      it('fetches issues with expected params', () => {
        expect(axiosMock.history.get[1].params).toMatchObject({
          page,
          per_page: PAGE_SIZE,
          state,
          with_labels_details: true,
        });
      });

      it('updates IssuableList with response data', () => {
        expect(findIssuableList().props()).toMatchObject({
          issuables: data,
          totalItems,
          currentPage: page,
          previousPage: page - 1,
          nextPage: page + 1,
          urlParams: { page, state },
        });
      });
    });

    describe('when "reorder" event is emitted by IssuableList', () => {
      const issueOne = { id: 1, iid: 101, title: 'Issue one' };
      const issueTwo = { id: 2, iid: 102, title: 'Issue two' };
      const issueThree = { id: 3, iid: 103, title: 'Issue three' };
      const issueFour = { id: 4, iid: 104, title: 'Issue four' };
      const issues = [issueOne, issueTwo, issueThree, issueFour];

      beforeEach(async () => {
        axiosMock.onGet(defaultProvide.endpoint).reply(200, issues, fetchIssuesResponse.headers);
        wrapper = mountComponent();
        await waitForPromises();
      });

      describe('when successful', () => {
        describe.each`
          description                       | issueToMove   | oldIndex | newIndex | moveBeforeId    | moveAfterId
          ${'to the beginning of the list'} | ${issueThree} | ${2}     | ${0}     | ${null}         | ${issueOne.id}
          ${'down the list'}                | ${issueOne}   | ${0}     | ${1}     | ${issueTwo.id}  | ${issueThree.id}
          ${'up the list'}                  | ${issueThree} | ${2}     | ${1}     | ${issueOne.id}  | ${issueTwo.id}
          ${'to the end of the list'}       | ${issueTwo}   | ${1}     | ${3}     | ${issueFour.id} | ${null}
        `(
          'when moving issue $description',
          ({ issueToMove, oldIndex, newIndex, moveBeforeId, moveAfterId }) => {
            it('makes API call to reorder the issue', async () => {
              findIssuableList().vm.$emit('reorder', { oldIndex, newIndex });

              await waitForPromises();

              expect(axiosMock.history.put[0]).toMatchObject({
                url: `${defaultProvide.issuesPath}/${issueToMove.iid}/reorder`,
                data: JSON.stringify({ move_before_id: moveBeforeId, move_after_id: moveAfterId }),
              });
            });
          },
        );
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
      it.each(Object.keys(apiSortParams))(
        'fetches issues with correct params with payload `%s`',
        async (sortKey) => {
          wrapper = mountComponent();

          findIssuableList().vm.$emit('sort', sortKey);

          await waitForPromises();

          expect(axiosMock.history.get[1].params).toEqual({
            page: xPage,
            per_page: sortKey === RELATIVE_POSITION_DESC ? PAGE_SIZE_MANUAL : PAGE_SIZE,
            state,
            with_labels_details: true,
            ...apiSortParams[sortKey],
          });
        },
      );
    });

    describe('when "update-legacy-bulk-edit" event is emitted by IssuableList', () => {
      beforeEach(() => {
        wrapper = mountComponent();
        jest.spyOn(eventHub, '$emit');
      });

      it('emits an "issuables:updateBulkEdit" event to the legacy bulk edit class', async () => {
        findIssuableList().vm.$emit('update-legacy-bulk-edit');

        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith('issuables:updateBulkEdit');
      });
    });

    describe('when "filter" event is emitted by IssuableList', () => {
      beforeEach(() => {
        wrapper = mountComponent();

        findIssuableList().vm.$emit('filter', filteredTokens);
      });

      it('makes an API call to search for issues with the search term', () => {
        expect(axiosMock.history.get[1].params).toMatchObject(apiParams);
      });

      it('updates IssuableList with url params', () => {
        expect(findIssuableList().props('urlParams')).toMatchObject(urlParams);
      });
    });
  });
});
