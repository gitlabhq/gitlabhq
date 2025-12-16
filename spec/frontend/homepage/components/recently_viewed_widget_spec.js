import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RecentlyViewedWidget from '~/homepage/components/recently_viewed_widget.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import RecentlyViewedItemsQuery from 'ee_else_ce/homepage/graphql/queries/recently_viewed_items.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import BaseWidget from '~/homepage/components/base_widget.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_RECENTLY_VIEWED,
} from '~/homepage/tracking_constants';

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
        recentlyViewedItems: [
          {
            viewedAt: '2025-06-21T09:15:00Z',
            itemType: 'MergeRequest',
            item: {
              __typename: 'MergeRequest',
              id: '!gl-mr-2',
              title: 'Implement authentication improvements',
              webUrl: '/project/-/merge_requests/456',
            },
          },
          {
            viewedAt: '2025-06-20T10:00:00Z',
            itemType: 'Issue',
            item: {
              __typename: 'Issue',
              id: 'issue-1',
              title: 'Fix critical bug in payment processing',
              webUrl: '/project/-/issues/123',
            },
          },
          {
            viewedAt: '2025-06-18T15:45:00Z',
            item: {
              __typename: 'Issue',
              id: 'issue-2',
              title: 'Add new feature for user management',
              webUrl: '/project/-/issues/124',
            },
          },
          {
            viewedAt: '2025-06-18T11:45:00Z',
            itemType: 'MergeRequest',
            item: {
              __typename: 'MergeRequest',
              id: '!gl-mr-3',
              title: 'Update documentation for API endpoints',
              webUrl: '/project/-/merge_requests/457',
            },
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
  const findErrorMessage = () =>
    wrapper.findByText(
      'Your recently viewed items are not available. Please refresh the page to try again.',
    );
  const findEmptyState = () =>
    wrapper.findByText('Issues and merge requests you visit will appear here.');
  const findItemsList = () => wrapper.find('ul');
  const findListItems = () => findItemsList().findAll('li');
  const findItemsByIconName = (iconName) =>
    findListItems().wrappers.filter((w) => w.findComponent(GlIcon).props('name') === iconName);
  const findItemLinks = () => wrapper.findAll('a[href^="/"]');
  const findItemIcons = () => wrapper.findAllComponents(GlIcon);
  const findTooltipComponents = () => wrapper.findAllComponents(TooltipOnTruncate);
  const findBaseWidget = () => wrapper.findComponent(BaseWidget);

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

    it('captures error with Sentry when query fails', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
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
            recentlyViewedItems: [],
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

      expect(findItemLinks()).toHaveLength(4);
    });

    it('handles empty response gracefully', async () => {
      const emptyResponse = {
        data: {
          currentUser: {
            id: 123,
            recentlyViewedItems: [],
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
      findBaseWidget().vm.$emit('visible');
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

    it('sorts items by viewedAt in descending order (most recent first)', () => {
      const items = findListItems();
      const { recentlyViewedItems } = mockRecentlyViewedResponse.data.currentUser;

      // Should be sorted by viewedAt (backend already sorts): !gl-mr-2, issue-1, issue-2, !gl-mr-3
      expect(items.at(0).text()).toBe(recentlyViewedItems[0].item.title);
      expect(items.at(1).text()).toBe(recentlyViewedItems[1].item.title);
      expect(items.at(2).text()).toBe(recentlyViewedItems[2].item.title);
      expect(items.at(3).text()).toBe(recentlyViewedItems[3].item.title);
    });

    it('limits items to MAX_ITEMS', async () => {
      const manyItemsResponse = {
        data: {
          currentUser: {
            id: 123,
            recentlyViewedItems: Array.from({ length: 15 }, (_, i) => ({
              viewedAt: new Date(Date.now() - i * 1000).toISOString(),
              itemType: 'Issue',
              item: {
                __typename: 'Issue',
                id: `issue-${i}`,
                title: `Issue ${i}`,
                webUrl: `/issues/${i}`,
              },
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
      const issueItems = findItemsByIconName('work-item-issue');

      expect(issueItems).toHaveLength(2);
      expect(issueItems.at(0).text()).toBe('Fix critical bug in payment processing');
    });

    it('adds correct icon to merge requests', () => {
      const mrItems = findItemsByIconName('merge-request');

      expect(mrItems).toHaveLength(2);
      expect(mrItems.at(0).text()).toBe('Implement authentication improvements');
    });

    it('renders items with correct URLs', () => {
      const links = findItemLinks();

      expect(links.at(0).attributes('href')).toBe('/project/-/merge_requests/456');
      expect(links.at(1).attributes('href')).toBe('/project/-/issues/123');
      expect(links.at(2).attributes('href')).toBe('/project/-/issues/124');
      expect(links.at(3).attributes('href')).toBe('/project/-/merge_requests/457');
    });

    it('renders items with correct icons', () => {
      const icons = findItemIcons();

      expect(icons.at(0).props('name')).toBe('merge-request');
      expect(icons.at(1).props('name')).toBe('work-item-issue');
      expect(icons.at(2).props('name')).toBe('work-item-issue');
      expect(icons.at(3).props('name')).toBe('merge-request');
    });

    it('renders tooltip components for each item', () => {
      const tooltips = findTooltipComponents();

      expect(tooltips).toHaveLength(4);
      expect(tooltips.at(0).props('title')).toBe('Implement authentication improvements');
      expect(tooltips.at(2).props('title')).toBe('Add new feature for user management');
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('tracks click on issue item', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      const mockIssueItem = { icon: 'work-item-issue', __typename: 'Issue' };
      wrapper.vm.handleItemClick(mockIssueItem);

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_RECENTLY_VIEWED,
          property: 'Issue',
        },
        undefined,
      );
    });

    it('tracks click on merge request item', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      const mockMrItem = { icon: 'merge-request', __typename: 'MergeRequest' };
      wrapper.vm.handleItemClick(mockMrItem);

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_RECENTLY_VIEWED,
          property: 'MergeRequest',
        },
        undefined,
      );
    });
  });
});
