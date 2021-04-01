import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/issuable_list/constants';
import IssuesListApp from '~/issues_list/components/issues_list_app.vue';

import {
  CREATED_DESC,
  PAGE_SIZE,
  PAGE_SIZE_MANUAL,
  RELATIVE_POSITION_ASC,
  sortOptions,
  sortParams,
} from '~/issues_list/constants';
import eventHub from '~/issues_list/eventhub';
import axios from '~/lib/utils/axios_utils';
import { setUrlParams } from '~/lib/utils/url_utility';

jest.mock('~/flash');

describe('IssuesListApp component', () => {
  const originalWindowLocation = window.location;
  let axiosMock;
  let wrapper;

  const calendarPath = 'calendar/path';
  const endpoint = 'api/endpoint';
  const exportCsvPath = 'export/csv/path';
  const fullPath = 'path/to/project';
  const issuesPath = `${fullPath}/-/issues`;
  const newIssuePath = `new/issue/path`;
  const rssPath = 'rss/path';
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

  const findGlButtons = () => wrapper.findAllComponents(GlButton);
  const findGlButtonAt = (index) => findGlButtons().at(index);
  const findIssuableList = () => wrapper.findComponent(IssuableList);

  const mountComponent = ({ provide = {} } = {}) =>
    shallowMount(IssuesListApp, {
      provide: {
        calendarPath,
        endpoint,
        exportCsvPath,
        fullPath,
        issuesPath,
        newIssuePath,
        rssPath,
        ...provide,
      },
    });

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(endpoint).reply(200, fetchIssuesResponse.data, fetchIssuesResponse.headers);
  });

  afterEach(() => {
    window.location = originalWindowLocation;
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
        namespace: fullPath,
        recentSearchesStorageKey: 'issues',
        searchInputPlaceholder: 'Search or filter results…',
        sortOptions,
        initialSortBy: CREATED_DESC,
        tabs: IssuableListTabs,
        currentTab: IssuableStates.Opened,
        tabCounts,
        showPaginationControls: true,
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
      wrapper = mountComponent();

      expect(findGlButtonAt(0).attributes()).toMatchObject({
        href: rssPath,
        icon: 'rss',
        'aria-label': IssuesListApp.i18n.rssLabel,
      });
    });

    it('renders calendar button', () => {
      wrapper = mountComponent();

      expect(findGlButtonAt(1).attributes()).toMatchObject({
        href: calendarPath,
        icon: 'calendar',
        'aria-label': IssuesListApp.i18n.calendarLabel,
      });
    });

    it('renders csv import/export component', async () => {
      const search = '?page=1&search=refactor';

      Object.defineProperty(window, 'location', {
        writable: true,
        value: { search },
      });

      wrapper = mountComponent();

      await waitForPromises();

      expect(wrapper.findComponent(CsvImportExportButtons).props()).toMatchObject({
        exportCsvPath: `${exportCsvPath}${search}`,
        issuableCount: xTotal,
      });
    });

    describe('bulk edit button', () => {
      it('renders when user has permissions', () => {
        wrapper = mountComponent({ provide: { canBulkUpdate: true } });

        expect(findGlButtonAt(2).text()).toBe('Edit issues');
      });

      it('does not render when user has permissions', () => {
        wrapper = mountComponent({ provide: { canBulkUpdate: false } });

        expect(findGlButtons().filter((button) => button.text() === 'Edit issues')).toHaveLength(0);
      });

      it('emits "issuables:enableBulkEdit" event to legacy bulk edit class', () => {
        wrapper = mountComponent({ provide: { canBulkUpdate: true } });

        jest.spyOn(eventHub, '$emit');

        findGlButtonAt(2).vm.$emit('click');

        expect(eventHub.$emit).toHaveBeenCalledWith('issuables:enableBulkEdit');
      });
    });

    describe('new issue button', () => {
      it('renders when user has permissions', () => {
        wrapper = mountComponent({ provide: { showNewIssueLink: true } });

        expect(findGlButtonAt(2).text()).toBe('New issue');
        expect(findGlButtonAt(2).attributes('href')).toBe(newIssuePath);
      });

      it('does not render when user does not have permissions', () => {
        wrapper = mountComponent({ provide: { showNewIssueLink: false } });

        expect(findGlButtons().filter((button) => button.text() === 'New issue')).toHaveLength(0);
      });
    });
  });

  describe('initial sort', () => {
    it.each(Object.keys(sortParams))('is set as %s when the url query matches', (sortKey) => {
      Object.defineProperty(window, 'location', {
        writable: true,
        value: {
          href: setUrlParams(sortParams[sortKey], TEST_HOST),
        },
      });

      wrapper = mountComponent();

      expect(findIssuableList().props()).toMatchObject({
        initialSortBy: sortKey,
        urlParams: sortParams[sortKey],
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

  describe('when "click-tab" event is emitted by IssuableList', () => {
    beforeEach(() => {
      axiosMock.onGet(endpoint).reply(200, fetchIssuesResponse.data, {
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
      axiosMock.onGet(endpoint).reply(200, data, {
        'x-page': page,
        'x-total': totalItems,
      });

      wrapper = mountComponent();

      findIssuableList().vm.$emit('page-change', page);

      await waitForPromises();
    });

    it('fetches issues with expected params', () => {
      expect(axiosMock.history.get[1].params).toEqual({
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
      axiosMock.onGet(endpoint).reply(200, issues, fetchIssuesResponse.headers);
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
              url: `${issuesPath}/${issueToMove.iid}/reorder`,
              data: JSON.stringify({ move_before_id: moveBeforeId, move_after_id: moveAfterId }),
            });
          });
        },
      );
    });

    describe('when unsuccessful', () => {
      it('displays an error message', async () => {
        axiosMock.onPut(`${issuesPath}/${issueOne.iid}/reorder`).reply(500);

        findIssuableList().vm.$emit('reorder', { oldIndex: 0, newIndex: 1 });

        await waitForPromises();

        expect(createFlash).toHaveBeenCalledWith({ message: IssuesListApp.i18n.reorderError });
      });
    });
  });

  describe('when "sort" event is emitted by IssuableList', () => {
    it.each(Object.keys(sortParams))(
      'fetches issues with correct params for "sort" payload `%s`',
      async (sortKey) => {
        wrapper = mountComponent();

        findIssuableList().vm.$emit('sort', sortKey);

        await waitForPromises();

        expect(axiosMock.history.get[1].params).toEqual({
          page: xPage,
          per_page: sortKey === RELATIVE_POSITION_ASC ? PAGE_SIZE_MANUAL : PAGE_SIZE,
          state,
          with_labels_details: true,
          ...sortParams[sortKey],
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
});
