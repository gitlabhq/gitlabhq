import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import WorkItemsWidget from '~/homepage/components/work_items_widget.vue';
import BaseWidget from '~/homepage/components/base_widget.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import workItemsWidgetMetadataQuery from '~/homepage/graphql/queries/work_items_widget_metadata.query.graphql';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_ISSUES,
  TRACKING_PROPERTY_ASSIGNED_TO_YOU,
  TRACKING_PROPERTY_AUTHORED_BY_YOU,
} from '~/homepage/tracking_constants';
import { userCounts } from '~/super_sidebar/user_counts_manager';
import { withItems, withoutItems } from './mocks/work_items_widget_metadata_query_mocks';

jest.mock('~/super_sidebar/user_counts_manager', () => ({
  userCounts: { assigned_issues: 0 },
  createUserCountsManager: jest.fn(),
  useCachedUserCounts: jest.fn(),
}));
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/super_sidebar/user_counts_fetch');

describe('WorkItemsWidget', () => {
  Vue.use(VueApollo);

  const MOCK_ASSIGNED_TO_YOU_PATH = '/assigned/to/you/path';
  const MOCK_AUTHORED_BY_YOU_PATH = '/authored/to/you/path';
  const MOCK_CURRENT_TIME = new Date('2025-06-29T18:13:25Z');

  useFakeDate(MOCK_CURRENT_TIME);

  const workItemsWidgetMetadataQuerySuccessHandler = (data) => jest.fn().mockResolvedValue(data);

  let wrapper;

  const findBaseWidget = () => wrapper.findComponent(BaseWidget);
  const findAssignedCard = () => wrapper.findAllComponents(GlLink).at(0);
  const findAuthoredCard = () => wrapper.findAllComponents(GlLink).at(1);
  const findAssignedCount = () => wrapper.findByTestId('assigned-count');
  const findAssignedLastUpdatedAt = () => wrapper.findByTestId('assigned-last-updated-at');
  const findAuthoredCount = () => wrapper.findByTestId('authored-count');
  const findAuthoredLastUpdatedAt = () => wrapper.findByTestId('authored-last-updated-at');

  afterEach(() => {
    jest.restoreAllMocks();
  });

  function createWrapper({
    workItemsWidgetMetadataQueryHandler = workItemsWidgetMetadataQuerySuccessHandler(withItems),
    assignedIssuesCount = 0,
  } = {}) {
    userCounts.assigned_issues = assignedIssuesCount;

    const mockApollo = createMockApollo([
      [workItemsWidgetMetadataQuery, workItemsWidgetMetadataQueryHandler],
    ]);
    wrapper = shallowMountExtended(WorkItemsWidget, {
      apolloProvider: mockApollo,
      propsData: {
        assignedToYouPath: MOCK_ASSIGNED_TO_YOU_PATH,
        authoredByYouPath: MOCK_AUTHORED_BY_YOU_PATH,
      },
      stubs: {
        GlSprintf,
        BaseWidget,
      },
    });
  }

  afterEach(() => {
    userCounts.assigned_issues = 0;
  });

  describe('cards', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the "Issues assigned to you" card', () => {
      const card = findAssignedCard();

      expect(card.exists()).toBe(true);
      expect(card.text()).toMatch('Issues assigned to you');
    });

    it('renders the "Issues authored by you" card', () => {
      const card = findAuthoredCard();

      expect(card.exists()).toBe(true);
      expect(card.text()).toMatch('Issues authored by you');
    });
  });

  describe('metadata', () => {
    it('shows the metadata once the query has resolved', async () => {
      createWrapper();
      await waitForPromises();

      expect(findAssignedLastUpdatedAt().text()).toBe('1 day ago');
      expect(findAuthoredLastUpdatedAt().text()).toBe('4 days ago');
    });

    it('shows partial metadata when the user has no relevant items', async () => {
      createWrapper({
        workItemsWidgetMetadataQueryHandler:
          workItemsWidgetMetadataQuerySuccessHandler(withoutItems),
      });
      await waitForPromises();

      expect(findAssignedLastUpdatedAt().exists()).toBe(false);
      expect(findAuthoredLastUpdatedAt().exists()).toBe(false);

      expect(findAssignedCount().text()).toBe('0');
      expect(findAuthoredCount().text()).toBe('0');
    });

    it('shows error messages in both cards if the query errors out', async () => {
      createWrapper({
        workItemsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
      });
      await waitForPromises();

      expect(findAssignedCard().text()).toContain(
        'The number of issues is not available. Please refresh the page to try again, or visit the issue list.',
      );
      expect(findAuthoredCard().text()).toContain(
        'The number of issues is not available. Please refresh the page to try again, or visit the issue list.',
      );
      expect(Sentry.captureException).toHaveBeenCalled();

      expect(findAssignedCard().text()).not.toMatch('Issues assigned to you');
      expect(findAuthoredCard().text()).not.toMatch('Issues authored by you');
    });

    it('shows error icons in both cards when in error state', async () => {
      createWrapper({
        workItemsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
      });
      await waitForPromises();
      const allIcons = wrapper.findAllComponents({ name: 'GlIcon' });

      let errorIconCount = 0;
      for (let i = 0; i < allIcons.length; i += 1) {
        const icon = allIcons.at(i);
        if (icon.props('name') === 'error') {
          expect(icon.props('size')).toBe(16);
          expect(icon.classes('gl-text-red-500')).toBe(true);
          errorIconCount += 1;
        }
      }

      expect(errorIconCount).toBe(2);
    });
  });

  describe('BaseWidget integration', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders BaseWidget without styling', () => {
      const baseWidget = findBaseWidget();

      expect(baseWidget.exists()).toBe(true);
      expect(baseWidget.props('applyDefaultStyling')).toBe(false);
    });

    it('handles visible event from BaseWidget', async () => {
      const workItemsWidgetMetadataQueryHandler =
        workItemsWidgetMetadataQuerySuccessHandler(withItems);

      createWrapper({ workItemsWidgetMetadataQueryHandler });
      await waitForPromises();
      expect(workItemsWidgetMetadataQueryHandler).toHaveBeenCalledTimes(1);

      const baseWidget = findBaseWidget();
      baseWidget.vm.$emit('visible');

      await waitForPromises();
      expect(workItemsWidgetMetadataQueryHandler).toHaveBeenCalledTimes(2);
    });

    it('calls reload method directly', async () => {
      createWrapper();
      await waitForPromises();

      const refetchSpy = jest.spyOn(wrapper.vm.$apollo.queries.metadata, 'refetch');

      wrapper.vm.reload();

      expect(wrapper.vm.hasError).toBe(false);
      expect(refetchSpy).toHaveBeenCalled();
    });

    it('handles visibility change when document is not hidden', async () => {
      let mockTime = Date.now();
      jest.spyOn(Date, 'now').mockImplementation(() => mockTime);

      const workItemsWidgetMetadataQueryHandler =
        workItemsWidgetMetadataQuerySuccessHandler(withItems);

      createWrapper({ workItemsWidgetMetadataQueryHandler });
      await waitForPromises();

      Object.defineProperty(document, 'hidden', {
        writable: true,
        value: false,
      });

      // Initial visibility change - sets timestamp but doesn't reload
      document.dispatchEvent(new Event('visibilitychange'));
      expect(workItemsWidgetMetadataQueryHandler).toHaveBeenCalledTimes(1);

      // Advance time and trigger another visibility change
      mockTime += 6000; // 6 seconds
      document.dispatchEvent(new Event('visibilitychange'));

      await waitForPromises();
      expect(workItemsWidgetMetadataQueryHandler).toHaveBeenCalledTimes(2);

      Date.now.mockRestore();
    });

    it('does not reload when document is hidden', async () => {
      const workItemsWidgetMetadataQueryHandler =
        workItemsWidgetMetadataQuerySuccessHandler(withItems);

      createWrapper({ workItemsWidgetMetadataQueryHandler });
      await waitForPromises();

      Object.defineProperty(document, 'hidden', {
        writable: true,
        value: true,
      });

      document.dispatchEvent(new Event('visibilitychange'));
      await waitForPromises();

      // Should not have queried again since document is hidden
      expect(workItemsWidgetMetadataQueryHandler).toHaveBeenCalledTimes(1);
    });
  });

  describe('number formatting', () => {
    it('formats large counts using formatNumberWithScale', async () => {
      const mockData = {
        data: {
          currentUser: {
            id: 'gid://gitlab/User/1',
            assigned: {
              count: 15000,
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/1',
                  updatedAt: '2025-06-28T18:13:25Z',
                  __typename: 'WorkItem',
                },
              ],
              __typename: 'WorkItemConnection',
            },
            authored: {
              count: 1500000,
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/2',
                  updatedAt: '2025-06-25T18:13:25Z',
                  __typename: 'WorkItem',
                },
              ],
              __typename: 'WorkItemConnection',
            },
            __typename: 'CurrentUser',
          },
        },
      };

      createWrapper({
        workItemsWidgetMetadataQueryHandler: workItemsWidgetMetadataQuerySuccessHandler(mockData),
        assignedIssuesCount: 15000,
      });
      await waitForPromises();

      expect(findAssignedCount().text()).toBe('15K');
      expect(findAuthoredCount().text()).toBe('1.5M');
    });

    it('formats small counts with grouping', async () => {
      const mockData = {
        data: {
          currentUser: {
            id: 'gid://gitlab/User/1',
            assigned: {
              count: 1234,
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/1',
                  updatedAt: '2025-06-28T18:13:25Z',
                  __typename: 'WorkItem',
                },
              ],
              __typename: 'WorkItemConnection',
            },
            authored: {
              count: 5678,
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/2',
                  updatedAt: '2025-06-25T18:13:25Z',
                  __typename: 'WorkItem',
                },
              ],
              __typename: 'WorkItemConnection',
            },
            __typename: 'CurrentUser',
          },
        },
      };

      createWrapper({
        workItemsWidgetMetadataQueryHandler: workItemsWidgetMetadataQuerySuccessHandler(mockData),
        assignedIssuesCount: 1234,
      });
      await waitForPromises();

      expect(findAssignedCount().text()).toBe('1,234');
      expect(findAuthoredCount().text()).toBe('5,678');
    });

    it('formats negative counts correctly', async () => {
      const mockData = {
        data: {
          currentUser: {
            id: 'gid://gitlab/User/1',
            assigned: {
              count: -1234,
              nodes: [],
              __typename: 'WorkItemConnection',
            },
            authored: {
              count: -25000,
              nodes: [],
              __typename: 'WorkItemConnection',
            },
            __typename: 'CurrentUser',
          },
        },
      };

      createWrapper({
        workItemsWidgetMetadataQueryHandler: workItemsWidgetMetadataQuerySuccessHandler(mockData),
        assignedIssuesCount: -1234,
      });
      await waitForPromises();

      expect(findAssignedCount().text()).toBe('-1,234');
      expect(findAuthoredCount().text()).toBe('-25K');
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('tracks click on "Issues assigned to you" card', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const assignedCard = findAssignedCard();

      assignedCard.vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_ISSUES,
          property: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
        },
        undefined,
      );
    });

    it('tracks click on "Issues authored by you" card', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const authoredCard = findAuthoredCard();

      authoredCard.vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_ISSUES,
          property: TRACKING_PROPERTY_AUTHORED_BY_YOU,
        },
        undefined,
      );
    });
  });
});
