import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { groupCommitsByDay } from '~/projects/commits/utils/commit_grouping';
import CommitListApp from '~/projects/commits/components/commit_list_app.vue';
import CommitListHeader from '~/projects/commits/components/commit_list_header.vue';
import CommitListItem from '~/projects/commits/components/commit_list_item.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import commitsQuery from '~/projects/commits/graphql/queries/commits.query.graphql';
import {
  TOKEN_TYPE_COMMITTED_AFTER,
  TOKEN_TYPE_COMMITTED_BEFORE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  mockCommitsNodes,
  mockCommitsQueryResponse,
  mockCommitsQueryResponseWithNextPage,
  mockCommitsQueryResponseSecondPage,
  mockEmptyCommitsQueryResponse,
} from './mock_data';

Vue.use(VueApollo);
Vue.use(VueRouter);

jest.mock('~/alert');
jest.mock('~/performance/utils');
jest.mock('~/projects/commits/utils/commit_grouping');

describe('CommitListApp', () => {
  let wrapper;

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const defaultProvide = {
    projectFullPath: 'gitlab-org/gitlab',
    escapedRef: 'main',
  };

  const commitsQueryHandler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);

  const createRouter = (routeQuery = {}) => {
    const router = new VueRouter({
      mode: 'abstract',
      routes: [{ path: '/', component: CommitListApp }],
    });

    router.push({ path: '/', query: routeQuery });

    return router;
  };

  const createComponent = (handler = commitsQueryHandler, routeQuery = {}) => {
    wrapper = shallowMountExtended(CommitListApp, {
      apolloProvider: createMockApollo([[commitsQuery, handler]]),
      provide: defaultProvide,
      router: createRouter(routeQuery),
    });
  };

  beforeEach(() => {
    window.performance.mark = jest.fn();
    window.performance.measure = jest.fn();
    window.performance.getEntriesByName = jest.fn().mockReturnValue([]);
    groupCommitsByDay.mockReturnValue([
      {
        day: '2025-06-23',
        commits: [mockCommitsNodes[0], mockCommitsNodes[1]],
      },
      {
        day: '2025-06-21',
        commits: [mockCommitsNodes[2]],
      },
    ]);
  });

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findCommitHeader = () => wrapper.findComponent(CommitListHeader);
  const findDailyCommits = () => wrapper.findAllByTestId('daily-commits');
  const findTimeElements = () => wrapper.findAll('time');
  const findEmptyState = () => wrapper.find('p');
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findPageSizeSelector = () => wrapper.findComponent(PageSizeSelector);

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render commits', () => {
      expect(findDailyCommits()).toHaveLength(0);
    });
  });

  describe('escapedRef decoding', () => {
    it('decodes percent-encoded escapedRef for the initial query', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
      wrapper = shallowMountExtended(CommitListApp, {
        apolloProvider: createMockApollo([[commitsQuery, handler]]),
        provide: {
          ...defaultProvide,
          escapedRef: 'feature%2Fmy-branch',
        },
        router: createRouter(),
      });
      await waitForPromises();

      expect(handler).toHaveBeenCalledWith(
        expect.objectContaining({
          ref: 'feature/my-branch',
        }),
      );
    });
  });

  describe('commit header', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the commit header component', () => {
      expect(findCommitHeader().exists()).toBe(true);
    });

    it('passes currentRef to the header component', () => {
      expect(findCommitHeader().props('currentRef')).toBe('main');
    });

    it('updates currentRef passed to header after ref change', async () => {
      findCommitHeader().vm.$emit('ref-change', 'develop');
      await waitForPromises();

      expect(findCommitHeader().props('currentRef')).toBe('develop');
    });
  });

  describe('commits data', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the correct number of day groups', () => {
      // mockCommitsNodes has 2 commits on 2025-06-23 and 1 on 2025-06-21
      expect(findDailyCommits()).toHaveLength(2);
    });

    it('hides loading icon after data loads', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('commit day rendering', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders time elements with correct data', () => {
      const timeElements = findTimeElements();
      expect(timeElements).toHaveLength(2);

      const expectedDateText = ['Jun 23, 2025', 'Jun 21, 2025'];
      const expectedDatetime = ['2025-06-23', '2025-06-21'];

      timeElements.wrappers.forEach((timeElement, index) => {
        expect(timeElement.attributes('datetime')).toBe(expectedDatetime[index]);
        expect(timeElement.text()).toBe(expectedDateText[index]);
      });
    });

    it('renders the raw day string when the authored date is outside the JS Date range', async () => {
      const outOfRangeDay = '+292278994-08-17T07:12:55+00:00';
      groupCommitsByDay.mockReturnValue([{ day: outOfRangeDay, commits: [mockCommitsNodes[0]] }]);
      createComponent();
      await waitForPromises();

      const timeElements = findTimeElements();
      expect(timeElements.at(0).attributes('datetime')).toBe(outOfRangeDay);
      expect(timeElements.at(0).text()).toBe(outOfRangeDay);
    });
  });

  describe('commit list items', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('passes correct commit data to each commit list item', () => {
      const firstDayCommits = findDailyCommits().at(0).findAllComponents(CommitListItem);

      expect(firstDayCommits).toHaveLength(2);

      expect(firstDayCommits.at(0).props('commit')).toMatchObject({
        id: mockCommitsNodes[0].id,
        title: mockCommitsNodes[0].title,
        authoredDate: mockCommitsNodes[0].authoredDate,
      });

      expect(firstDayCommits.at(1).props('commit')).toMatchObject({
        id: mockCommitsNodes[1].id,
        title: mockCommitsNodes[1].title,
        authoredDate: mockCommitsNodes[1].authoredDate,
      });

      const secondDayCommits = findDailyCommits().at(1).findAllComponents(CommitListItem);

      expect(secondDayCommits).toHaveLength(1);

      expect(secondDayCommits.at(0).props('commit')).toMatchObject({
        id: mockCommitsNodes[2].id,
        title: mockCommitsNodes[2].title,
        authoredDate: mockCommitsNodes[2].authoredDate,
      });
    });
  });

  describe('when no commits exist', () => {
    beforeEach(async () => {
      groupCommitsByDay.mockReturnValue([]);
      createComponent(jest.fn().mockResolvedValue(mockEmptyCommitsQueryResponse));
      await waitForPromises();
    });

    it('renders empty state message', () => {
      expect(findEmptyState().text()).toBe('No commits found');
    });

    it('does not render day groups', () => {
      expect(findDailyCommits()).toHaveLength(0);
    });
  });

  describe('when query fails', () => {
    it('shows error alert with error message', async () => {
      createComponent(jest.fn().mockRejectedValue(new Error('Custom error message')));
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Custom error message',
          captureError: true,
        }),
      );
    });

    it('shows fallback error message when error has no message', async () => {
      createAlert.mockClear();
      createComponent(jest.fn().mockRejectedValue(new Error()));
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Something went wrong while loading commits. Please try again.',
          captureError: true,
        }),
      );
    });
  });

  describe('ref change', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('refetches commits with new ref when ref-change is emitted', async () => {
      commitsQueryHandler.mockClear();

      findCommitHeader().vm.$emit('ref-change', 'feature-branch');
      await waitForPromises();

      expect(commitsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          ref: 'feature-branch',
        }),
      );
    });

    it('resets pagination when ref changes', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponseWithNextPage);
      createComponent(handler);
      await waitForPromises();

      findPagination().vm.$emit('next');
      await waitForPromises();

      handler.mockClear();
      findCommitHeader().vm.$emit('ref-change', 'other-branch');
      await waitForPromises();

      expect(handler).toHaveBeenCalledWith(
        expect.objectContaining({
          ref: 'other-branch',
          after: null,
        }),
      );
    });
  });

  describe('filtering', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('refetches commits with author filter when filter is applied', async () => {
      commitsQueryHandler.mockClear();

      findCommitHeader().vm.$emit('filter', [{ type: 'author', value: { data: 'Administrator' } }]);
      await waitForPromises();

      expect(commitsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          author: 'Administrator',
          query: null,
        }),
      );
    });

    it('refetches commits with message filter when filter is applied', async () => {
      commitsQueryHandler.mockClear();

      findCommitHeader().vm.$emit('filter', [{ type: 'message', value: { data: 'fix bug' } }]);
      await waitForPromises();

      expect(commitsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          author: null,
          query: 'fix bug',
        }),
      );
    });

    it('treats free text search as message filter', async () => {
      commitsQueryHandler.mockClear();

      findCommitHeader().vm.$emit('filter', [
        { type: 'filtered-search-term', value: { data: 'search term' } },
      ]);
      await waitForPromises();

      expect(commitsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          query: 'search term',
        }),
      );
    });

    it('refetches commits with committed-after filter when filter is applied', async () => {
      commitsQueryHandler.mockClear();

      findCommitHeader().vm.$emit('filter', [
        { type: TOKEN_TYPE_COMMITTED_AFTER, value: { data: '2025-01-01' } },
      ]);
      await waitForPromises();

      expect(commitsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          committedAfter: '2025-01-01',
          committedBefore: null,
        }),
      );
    });

    it('refetches commits with committed-before filter when filter is applied', async () => {
      commitsQueryHandler.mockClear();

      findCommitHeader().vm.$emit('filter', [
        { type: TOKEN_TYPE_COMMITTED_BEFORE, value: { data: '2025-12-31' } },
      ]);
      await waitForPromises();

      expect(commitsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          committedAfter: null,
          committedBefore: '2025-12-31',
        }),
      );
    });

    it('refetches commits with date range filters when both are applied', async () => {
      commitsQueryHandler.mockClear();

      findCommitHeader().vm.$emit('filter', [
        { type: TOKEN_TYPE_COMMITTED_AFTER, value: { data: '2025-01-01' } },
        { type: TOKEN_TYPE_COMMITTED_BEFORE, value: { data: '2025-12-31' } },
      ]);
      await waitForPromises();

      expect(commitsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          committedAfter: '2025-01-01',
          committedBefore: '2025-12-31',
        }),
      );
    });

    it('clears filters when empty filter array is passed', async () => {
      findCommitHeader().vm.$emit('filter', [{ type: 'author', value: { data: 'Administrator' } }]);
      await waitForPromises();

      findCommitHeader().vm.$emit('filter', []);
      await waitForPromises();

      expect(findDailyCommits()).toHaveLength(2);
    });
  });

  describe('filter_commit_list event tracking', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('tracks filter event with author label', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findCommitHeader().vm.$emit('filter', [{ type: 'author', value: { data: 'Administrator' } }]);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'filter_commit_list',
        { label: 'author' },
        undefined,
      );
    });

    it('tracks filter event with message label', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findCommitHeader().vm.$emit('filter', [{ type: 'message', value: { data: 'fix bug' } }]);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'filter_commit_list',
        { label: 'message' },
        undefined,
      );
    });

    it('tracks filter event with message label for filtered-search-term token type', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findCommitHeader().vm.$emit('filter', [
        { type: 'filtered-search-term', value: { data: 'fix bug' } },
      ]);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'filter_commit_list',
        { label: 'message' },
        undefined,
      );
    });

    it('tracks filter event with combined label when both filters are applied', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findCommitHeader().vm.$emit('filter', [
        { type: 'author', value: { data: 'Administrator' } },
        { type: 'message', value: { data: 'fix bug' } },
      ]);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'filter_commit_list',
        { label: 'author,message' },
        undefined,
      );
    });

    it('tracks filter event with committed-after label', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findCommitHeader().vm.$emit('filter', [
        { type: TOKEN_TYPE_COMMITTED_AFTER, value: { data: '2025-01-01' } },
      ]);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'filter_commit_list',
        { label: 'committed-after' },
        undefined,
      );
    });

    it('tracks filter event with committed-before label', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findCommitHeader().vm.$emit('filter', [
        { type: TOKEN_TYPE_COMMITTED_BEFORE, value: { data: '2025-12-31' } },
      ]);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'filter_commit_list',
        { label: 'committed-before' },
        undefined,
      );
    });

    it('tracks filter event with date range labels when both date filters are applied', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findCommitHeader().vm.$emit('filter', [
        { type: TOKEN_TYPE_COMMITTED_AFTER, value: { data: '2025-01-01' } },
        { type: TOKEN_TYPE_COMMITTED_BEFORE, value: { data: '2025-12-31' } },
      ]);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'filter_commit_list',
        { label: 'committed-after,committed-before' },
        undefined,
      );
    });

    it('tracks filter event with none label when filters are cleared', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findCommitHeader().vm.$emit('filter', []);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'filter_commit_list',
        { label: 'none' },
        undefined,
      );
    });
  });

  describe('pagination', () => {
    describe('when there is no next page', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('does not render pagination buttons but still shows page size selector', () => {
        expect(findPagination().exists()).toBe(false);
        expect(findPageSizeSelector().exists()).toBe(true);
      });
    });

    describe('when there is a next page', () => {
      let handler;

      beforeEach(async () => {
        handler = jest.fn().mockResolvedValue(mockCommitsQueryResponseWithNextPage);
        createComponent(handler);
        await waitForPromises();
      });

      it('renders pagination controls', () => {
        expect(findPagination().exists()).toBe(true);
        expect(findPageSizeSelector().exists()).toBe(true);
      });

      it('passes correct props to pagination', () => {
        expect(findPagination().props()).toMatchObject({
          hasPreviousPage: false,
          hasNextPage: true,
        });
      });

      it('fetches next page when clicking next', async () => {
        handler.mockClear();
        findPagination().vm.$emit('next');
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ after: 'end-cursor-1' }));
      });

      it('enables previous button after navigating to next page', async () => {
        handler.mockResolvedValue(mockCommitsQueryResponseSecondPage);
        findPagination().vm.$emit('next');
        await waitForPromises();

        expect(findPagination().props('hasPreviousPage')).toBe(true);
      });

      it('navigates back to first page when clicking prev', async () => {
        handler.mockResolvedValue(mockCommitsQueryResponseSecondPage);
        findPagination().vm.$emit('next');
        await waitForPromises();

        expect(findPagination().props('hasPreviousPage')).toBe(true);

        findPagination().vm.$emit('prev');
        await waitForPromises();

        expect(findPagination().props('hasPreviousPage')).toBe(false);
      });
    });

    describe('page size selector', () => {
      let handler;

      beforeEach(async () => {
        handler = jest.fn().mockResolvedValue(mockCommitsQueryResponseWithNextPage);
        createComponent(handler);
        await waitForPromises();
      });

      it('refetches with new page size when changed', async () => {
        handler.mockClear();
        findPageSizeSelector().vm.$emit('input', 50);
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ first: 50 }));
      });

      it('resets to first page when page size changes', async () => {
        findPagination().vm.$emit('next');
        await waitForPromises();

        handler.mockClear();
        findPageSizeSelector().vm.$emit('input', 50);
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ after: null }));
      });
    });

    describe('when filters are applied', () => {
      let handler;

      beforeEach(async () => {
        handler = jest.fn().mockResolvedValue(mockCommitsQueryResponseWithNextPage);
        createComponent(handler);
        await waitForPromises();
      });

      it('resets pagination when filter changes', async () => {
        findPagination().vm.$emit('next');
        await waitForPromises();

        handler.mockClear();
        findCommitHeader().vm.$emit('filter', [
          { type: 'author', value: { data: 'Administrator' } },
        ]);
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ after: null }));
      });
    });
  });

  describe('URL synchronization', () => {
    describe('reading from URL on mount', () => {
      it('initializes filters from URL query parameters', async () => {
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
        createComponent(handler, { author: 'john.doe', message: 'fix bug', page_size: '50' });
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(
          expect.objectContaining({
            author: 'john.doe',
            query: 'fix bug',
            first: 50,
          }),
        );

        expect(findCommitHeader().props('initialFilterTokens')).toEqual([
          { type: 'author', value: { data: 'john.doe', operator: '=' } },
          { type: 'message', value: { data: 'fix bug', operator: '=' } },
        ]);
      });

      it('uses default values when URL has no query parameters', async () => {
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
        createComponent(handler, {});
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(
          expect.objectContaining({
            author: null,
            query: null,
            first: 20,
          }),
        );

        expect(findCommitHeader().props('initialFilterTokens')).toEqual([]);
      });

      it('handles invalid page_size by using default', async () => {
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
        createComponent(handler, { page_size: 'invalid' });
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ first: 20 }));
      });
    });

    describe('writing to URL when filters change', () => {
      it.each`
        description               | filters                                                                                             | expectedQuery
        ${'author only'}          | ${[{ type: 'author', value: { data: 'john' } }]}                                                    | ${{ author: 'john' }}
        ${'message only'}         | ${[{ type: 'message', value: { data: 'fix bug' } }]}                                                | ${{ message: 'fix bug' }}
        ${'author and message'}   | ${[{ type: 'author', value: { data: 'admin' } }, { type: 'message', value: { data: 'refactor' } }]} | ${{ author: 'admin', message: 'refactor' }}
        ${'clearing all filters'} | ${[]}                                                                                               | ${{}}
      `('updates URL when $description', async ({ filters, expectedQuery }) => {
        createComponent(commitsQueryHandler, filters.length === 0 ? { author: 'existing' } : {});
        await waitForPromises();

        const pushSpy = jest.spyOn(wrapper.vm.$router, 'push');

        findCommitHeader().vm.$emit('filter', filters);
        await waitForPromises();

        expect(pushSpy).toHaveBeenCalledWith({ query: expectedQuery });
      });

      it('updates URL with page_size when changed', async () => {
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponseWithNextPage);
        createComponent(handler);
        await waitForPromises();

        const pushSpy = jest.spyOn(wrapper.vm.$router, 'push');

        findPageSizeSelector().vm.$emit('input', 50);
        await waitForPromises();

        expect(pushSpy).toHaveBeenCalledWith({ query: { page_size: '50' } });
      });

      it('omits page_size from URL when it equals default', async () => {
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponseWithNextPage);
        createComponent(handler, { page_size: '50' });
        await waitForPromises();

        const pushSpy = jest.spyOn(wrapper.vm.$router, 'push');

        findPageSizeSelector().vm.$emit('input', 20);
        await waitForPromises();

        expect(pushSpy).toHaveBeenCalledWith({ query: {} });
      });

      it('preserves page_size when filters change', async () => {
        createComponent(commitsQueryHandler, { page_size: '50' });
        await waitForPromises();

        const pushSpy = jest.spyOn(wrapper.vm.$router, 'push');

        findCommitHeader().vm.$emit('filter', [{ type: 'author', value: { data: 'admin' } }]);
        await waitForPromises();

        expect(pushSpy).toHaveBeenCalledWith({ query: { author: 'admin', page_size: '50' } });
      });

      it('does not update URL if query has not changed', async () => {
        createComponent(commitsQueryHandler, { author: 'admin' });
        await waitForPromises();

        const pushSpy = jest.spyOn(wrapper.vm.$router, 'push');

        findCommitHeader().vm.$emit('filter', [{ type: 'author', value: { data: 'admin' } }]);
        await waitForPromises();

        expect(pushSpy).not.toHaveBeenCalled();
      });
    });

    describe('route watcher for browser navigation', () => {
      it('refetches commits with new filters when route changes', async () => {
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
        createComponent(handler);
        await waitForPromises();

        handler.mockClear();

        await wrapper.vm.$router.push({ query: { author: 'new-author', message: 'fix' } });
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(
          expect.objectContaining({
            author: 'new-author',
            query: 'fix',
          }),
        );

        expect(findCommitHeader().props('initialFilterTokens')).toEqual([
          { type: 'author', value: { data: 'new-author', operator: '=' } },
          { type: 'message', value: { data: 'fix', operator: '=' } },
        ]);
      });

      it('resets pagination when route changes', async () => {
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponseWithNextPage);
        createComponent(handler);
        await waitForPromises();

        findPagination().vm.$emit('next');
        await waitForPromises();

        handler.mockClear();

        await wrapper.vm.$router.push({ query: { author: 'admin' } });
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ after: null }));
      });
    });

    describe('ref changes via route path', () => {
      it('extracts and uses ref from initial route path', async () => {
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
        createComponent(handler);
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ ref: 'main' }));
      });

      it('handles encoded refs in initial route path', async () => {
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
        wrapper = shallowMountExtended(CommitListApp, {
          apolloProvider: createMockApollo([[commitsQuery, handler]]),
          provide: {
            ...defaultProvide,
            escapedRef: 'feature%2Fmy-branch',
          },
          router: createRouter(),
        });
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ ref: 'feature/my-branch' }));
      });

      it('resolves the full ref when escapedRef contains an unencoded slash', async () => {
        // The backend sends escapedRef without encoding '/' (escape_path
        // preserves it), so the static route contains literal slashes.
        // syncRefFromRoute must use the injected escapedRef instead of
        // parsing the route path segments.
        const escapedRef = 'feature/my-branch';
        const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
        const router = new VueRouter({
          mode: 'abstract',
          routes: [
            { path: `/${escapedRef}/:path*`, name: 'commitsPath', component: CommitListApp },
            {
              path: `/${decodeURI(escapedRef)}/:path*`,
              name: 'commitsPathDecoded',
              component: CommitListApp,
            },
            { path: '/:ref/:path*', name: 'commitsAnyRef', component: CommitListApp },
          ],
        });
        await router.push('/feature/my-branch/');

        wrapper = shallowMountExtended(CommitListApp, {
          apolloProvider: createMockApollo([[commitsQuery, handler]]),
          provide: { ...defaultProvide, escapedRef },
          router,
        });
        await waitForPromises();

        // Must send the full ref, not just 'feature'
        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ ref: 'feature/my-branch' }));
      });
    });
  });

  describe('file path filtering', () => {
    const createPathRouter = (filePath = '', routeQuery = {}) => {
      const router = new VueRouter({
        mode: 'abstract',
        routes: [
          { path: '/main/:path*', name: 'commitsPath', component: CommitListApp },
          { path: '/:ref/:path*', name: 'commitsAnyRef', component: CommitListApp },
          { path: '/:pathMatch(.*)*', redirect: '/main' },
        ],
      });
      router.push({ path: filePath ? `/main/${filePath}` : '/main', query: routeQuery });
      return router;
    };

    const createComponentWithPath = (handler, filePath = '', routeQuery = {}) => {
      wrapper = shallowMountExtended(CommitListApp, {
        apolloProvider: createMockApollo([[commitsQuery, handler]]),
        provide: defaultProvide,
        router: createPathRouter(filePath, routeQuery),
      });
    };

    it('passes file path to GraphQL query', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
      createComponentWithPath(handler, 'app/models/user.rb');
      await waitForPromises();

      expect(handler).toHaveBeenCalledWith(expect.objectContaining({ path: 'app/models/user.rb' }));
    });

    it('passes null path when no file path in route', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
      createComponentWithPath(handler);
      await waitForPromises();

      expect(handler).toHaveBeenCalledWith(expect.objectContaining({ path: null }));
    });

    it('preserves file path after ref change', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
      createComponentWithPath(handler, 'app/models/user.rb');
      await waitForPromises();

      handler.mockClear();
      findCommitHeader().vm.$emit('ref-change', 'develop');
      await waitForPromises();

      expect(handler).toHaveBeenCalledWith(
        expect.objectContaining({ ref: 'develop', path: 'app/models/user.rb' }),
      );
    });

    it('updates path when navigating via breadcrumbs', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
      createComponentWithPath(handler, 'app/models/user.rb');
      await waitForPromises();

      handler.mockClear();

      await wrapper.vm.$router.push('/main/app/models');
      await waitForPromises();

      expect(handler).toHaveBeenCalledWith(expect.objectContaining({ path: 'app/models' }));
    });

    it('preserves path when switching ref hits the wildcard fallback route', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
      createComponentWithPath(handler, 'app/models/user.rb');
      await waitForPromises();

      // Navigate to a different ref — matches the 'commitsAnyRef' wildcard route.
      // The ref is a single segment so params.path is reliable.
      await wrapper.vm.$router.push('/develop/app/models/user.rb');
      await waitForPromises();

      expect(wrapper.vm.currentPath).toBe('app/models/user.rb');
    });

    it('correctly parses ref with slashes via the wildcard fallback route', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
      createComponentWithPath(handler, 'app/models/user.rb');
      await waitForPromises();

      handler.mockClear();

      // Refs containing '/' are encoded with encodeURIComponent so the
      // ref becomes a single path segment (feature%2Ffoo).
      await wrapper.vm.$router.push(`/${encodeURIComponent('feature/foo')}/app/models/user.rb`);
      await waitForPromises();

      expect(handler).toHaveBeenCalledWith(
        expect.objectContaining({ ref: 'feature/foo', path: 'app/models/user.rb' }),
      );
    });

    it('resolves ref on browser back to a previously visited slashed ref', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);
      createComponentWithPath(handler);
      await waitForPromises();

      // Simulate switching to a slashed ref, then switching away, then
      // navigating back (browser back).  The back navigation is a plain
      // router.push without a ref-change emit — only the route watcher fires.
      const refA = 'feature/foo';
      const refB = 'bugfix/bar';

      // Switch to refA (in-app: ref-change + router push)
      findCommitHeader().vm.$emit('ref-change', refA);
      await wrapper.vm.$router.push(`/${encodeURIComponent(refA)}/`);
      await waitForPromises();

      // Switch to refB
      findCommitHeader().vm.$emit('ref-change', refB);
      await wrapper.vm.$router.push(`/${encodeURIComponent(refB)}/`);
      await waitForPromises();

      // Verify we're on refB
      expect(wrapper.vm.currentRef).toBe(refB);

      handler.mockClear();

      // Browser back to refA — only the route changes, no ref-change event.
      // This is the scenario that broke before: syncRefFromRoute must parse
      // the encoded ref from route.params.ref.
      wrapper.vm.$router.back();
      await waitForPromises();

      expect(wrapper.vm.currentRef).toBe(refA);
    });

    it('resets pagination when route path changes', async () => {
      const handler = jest.fn().mockResolvedValue(mockCommitsQueryResponseWithNextPage);
      createComponentWithPath(handler, 'app/models/user.rb');
      await waitForPromises();

      findPagination().vm.$emit('next');
      await waitForPromises();

      handler.mockClear();

      await wrapper.vm.$router.push('/main/app');
      await waitForPromises();

      expect(handler).toHaveBeenCalledWith(expect.objectContaining({ path: 'app', after: null }));
    });
  });
});
