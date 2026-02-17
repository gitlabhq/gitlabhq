import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { groupCommitsByDay } from '~/projects/commits/utils';
import CommitListApp from '~/projects/commits/components/commit_list_app.vue';
import CommitListHeader from '~/projects/commits/components/commit_list_header.vue';
import CommitListItem from '~/projects/commits/components/commit_list_item.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import commitsQuery from '~/projects/commits/graphql/queries/commits.query.graphql';
import {
  mockCommitsNodes,
  mockCommitsQueryResponse,
  mockCommitsQueryResponseWithNextPage,
  mockCommitsQueryResponseSecondPage,
  mockEmptyCommitsQueryResponse,
} from './mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/projects/commits/utils');

describe('CommitListApp', () => {
  let wrapper;

  const defaultProvide = {
    projectFullPath: 'gitlab-org/gitlab',
    escapedRef: 'main',
  };

  const commitsQueryHandler = jest.fn().mockResolvedValue(mockCommitsQueryResponse);

  const createComponent = (handler = commitsQueryHandler) => {
    wrapper = shallowMountExtended(CommitListApp, {
      apolloProvider: createMockApollo([[commitsQuery, handler]]),
      provide: defaultProvide,
    });
  };

  beforeEach(() => {
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

  describe('commit header', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the commit header component', () => {
      expect(findCommitHeader().exists()).toBe(true);
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

    it('clears filters when empty filter array is passed', async () => {
      findCommitHeader().vm.$emit('filter', [{ type: 'author', value: { data: 'Administrator' } }]);
      await waitForPromises();

      findCommitHeader().vm.$emit('filter', []);
      await waitForPromises();

      expect(findDailyCommits()).toHaveLength(2);
    });
  });

  describe('pagination', () => {
    describe('when there is no next page', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('does not render pagination controls', () => {
        expect(findPagination().exists()).toBe(false);
        expect(findPageSizeSelector().exists()).toBe(false);
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
});
