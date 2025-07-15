import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RecentlyViewedWidget from '~/homepage/components/recently_viewed_widget.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import RecentlyViewedItemsQuery from '~/homepage/graphql/queries/recently_viewed_items.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import VisibilityChangeDetector from '~/homepage/components/visibility_change_detector.vue';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper', () => ({
  captureException: jest.fn(),
}));

describe('RecentlyViewedWidget', () => {
  let wrapper;

  const mockRecentlyViewedResponse = {
    data: {
      currentUser: {
        id: 123,
        recentlyViewedIssues: [
          {
            id: 'issue-1',
            title: 'Fix critical bug in payment processing',
            webUrl: '/project/-/issues/123',
            updatedAt: '2025-06-20T10:00:00Z',
          },
          {
            id: 'issue-2',
            title: 'Add new feature for user management',
            webUrl: '/project/-/issues/124',
            updatedAt: '2025-06-19T15:30:00Z',
          },
        ],
        recentlyViewedMergeRequests: [
          {
            id: 'mr-1',
            title: 'Implement authentication improvements',
            webUrl: '/project/-/merge_requests/456',
            updatedAt: '2025-06-21T09:15:00Z',
          },
          {
            id: 'mr-2',
            title: 'Update documentation for API endpoints',
            webUrl: '/project/-/merge_requests/457',
            updatedAt: '2025-06-18T11:45:00Z',
          },
        ],
      },
    },
  };

  const recentlyViewedQuerySuccessHandler = jest.fn().mockResolvedValue(mockRecentlyViewedResponse);
  const recentlyViewedQueryErrorHandler = jest.fn().mockRejectedValue(new Error('GraphQL Error'));

  const createComponent = ({ queryHandler = recentlyViewedQuerySuccessHandler } = {}) => {
    const mockApollo = createMockApollo([[RecentlyViewedItemsQuery, queryHandler]]);

    wrapper = shallowMountExtended(RecentlyViewedWidget, {
      apolloProvider: mockApollo,
    });
  };

  const findSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findErrorMessage = () => wrapper.findByText('Something went wrong.');
  const findRetryButton = () => wrapper.findComponent(GlButton);
  const findEmptyState = () =>
    wrapper.findByText('Issues and merge requests you visit will appear here.');
  const findItemsList = () => wrapper.find('ul');
  const findItemLinks = () => wrapper.findAll('a[href^="/"]');
  const findItemIcons = () => wrapper.findAllComponents(GlIcon);
  const findTooltipComponents = () => wrapper.findAllComponents(TooltipOnTruncate);
  const findDetector = () => wrapper.findComponent(VisibilityChangeDetector);

  describe('loading state', () => {
    it('shows skeleton loaders while fetching data', () => {
      createComponent();

      expect(findSkeletonLoaders()).toHaveLength(10);
      expect(findItemsList().exists()).toBe(false);
    });

    it('hides skeleton loaders after data is fetched', async () => {
      createComponent();
      await waitForPromises();

      expect(findSkeletonLoaders()).toHaveLength(0);
      expect(findItemsList().exists()).toBe(true);
    });
  });

  describe('error state', () => {
    beforeEach(async () => {
      createComponent({ queryHandler: recentlyViewedQueryErrorHandler });
      await waitForPromises();
    });

    it('shows error message when query fails', () => {
      expect(findErrorMessage().exists()).toBe(true);
    });

    it('shows retry link when query fails', () => {
      expect(findRetryButton().exists()).toBe(true);
    });

    it('captures error with Sentry when query fails', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
    });

    it('retries query when retry link is clicked', async () => {
      // Mock the refetch method to succeed on retry
      const mockRefetch = jest.fn().mockResolvedValue(mockRecentlyViewedResponse);
      wrapper.vm.$apollo.queries.items.refetch = mockRefetch;

      await findRetryButton().vm.$emit('click');
      await nextTick();

      expect(mockRefetch).toHaveBeenCalled();
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('does not show items list during error state', () => {
      expect(findItemsList().exists()).toBe(false);
    });
  });

  describe('empty state', () => {
    it('shows empty state when there are no items', async () => {
      const emptyResponse = {
        data: {
          currentUser: {
            id: 123,
            recentlyViewedIssues: [],
            recentlyViewedMergeRequests: [],
          },
        },
      };

      const emptyQueryHandler = jest.fn().mockResolvedValue(emptyResponse);
      createComponent({ queryHandler: emptyQueryHandler });
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findItemsList().exists()).toBe(false);
    });

    it('does not show empty state when loading', () => {
      createComponent();

      expect(findEmptyState().exists()).toBe(false);
    });

    it('does not show empty state when there are items', async () => {
      createComponent();
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(false);
      expect(findItemsList().exists()).toBe(true);
    });
  });

  describe('GraphQL query', () => {
    it('makes the correct GraphQL query', () => {
      createComponent();

      expect(recentlyViewedQuerySuccessHandler).toHaveBeenCalled();
    });

    it('updates component data when query resolves', async () => {
      createComponent();
      await waitForPromises();

      expect(findItemLinks()).toHaveLength(4); // 2 issues + 2 MRs
    });

    it('handles empty response gracefully', async () => {
      const emptyResponse = {
        data: {
          currentUser: {
            id: 123,
            recentlyViewedIssues: [],
            recentlyViewedMergeRequests: [],
          },
        },
      };

      const emptyQueryHandler = jest.fn().mockResolvedValue(emptyResponse);
      createComponent({ queryHandler: emptyQueryHandler });
      await waitForPromises();

      expect(wrapper.vm.items).toEqual([]);
    });
  });

  describe('refresh functionality', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('refreshes on becoming visible again', async () => {
      const refetchSpy = jest.spyOn(wrapper.vm.$apollo.queries.items, 'refetch');
      findDetector().vm.$emit('visible');
      await waitForPromises();

      expect(refetchSpy).toHaveBeenCalled();
      refetchSpy.mockRestore();
    });
  });

  describe('items rendering', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the correct number of items', () => {
      expect(findItemLinks()).toHaveLength(4);
    });

    it('sorts items by updatedAt in descending order', () => {
      const { items } = wrapper.vm;

      // Should be sorted: mr-1 (2025-06-21), issue-1 (2025-06-20), issue-2 (2025-06-19), mr-2 (2025-06-18)
      expect(items[0].id).toBe('mr-1');
      expect(items[1].id).toBe('issue-1');
      expect(items[2].id).toBe('issue-2');
      expect(items[3].id).toBe('mr-2');
    });

    it('limits items to MAX_ITEMS', async () => {
      // Create response with more than 10 items
      const manyItemsResponse = {
        data: {
          currentUser: {
            id: 123,
            recentlyViewedIssues: Array.from({ length: 8 }, (_, i) => ({
              id: `issue-${i}`,
              title: `Issue ${i}`,
              webUrl: `/issues/${i}`,
              updatedAt: new Date(Date.now() - i * 1000).toISOString(),
            })),
            recentlyViewedMergeRequests: Array.from({ length: 8 }, (_, i) => ({
              id: `mr-${i}`,
              title: `MR ${i}`,
              webUrl: `/mrs/${i}`,
              updatedAt: new Date(Date.now() - (i + 8) * 1000).toISOString(),
            })),
          },
        },
      };

      const manyItemsHandler = jest.fn().mockResolvedValue(manyItemsResponse);
      createComponent({ queryHandler: manyItemsHandler });
      await waitForPromises();

      expect(findItemLinks()).toHaveLength(10);
    });

    it('adds correct icon to issues', () => {
      const issueItems = wrapper.vm.items.filter((item) => item.icon === 'issues');

      expect(issueItems).toHaveLength(2);
      expect(issueItems[0].id).toBe('issue-1');
    });

    it('adds correct icon to merge requests', () => {
      const mrItems = wrapper.vm.items.filter((item) => item.icon === 'merge-request');

      expect(mrItems).toHaveLength(2);
      expect(mrItems[0].id).toBe('mr-1');
    });

    it('renders items with correct URLs', () => {
      const links = findItemLinks();

      expect(links.at(0).attributes('href')).toBe('/project/-/merge_requests/456');
      expect(links.at(1).attributes('href')).toBe('/project/-/issues/123');
    });

    it('renders items with correct icons', () => {
      const icons = findItemIcons();

      expect(icons.at(0).props('name')).toBe('merge-request'); // First item is MR
      expect(icons.at(1).props('name')).toBe('issues'); // Second item is issue
    });

    it('renders tooltip components for each item', () => {
      const tooltips = findTooltipComponents();

      expect(tooltips).toHaveLength(4);
      expect(tooltips.at(0).props('title')).toBe('Implement authentication improvements');
    });
  });
});
