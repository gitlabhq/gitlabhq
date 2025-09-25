import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import MergeRequestsWidget from '~/homepage/components/merge_requests_widget.vue';
import BaseWidget from '~/homepage/components/base_widget.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import mergeRequestsWidgetMetadataQuery from '~/homepage/graphql/queries/merge_requests_widget_metadata.query.graphql';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_MERGE_REQUESTS,
  TRACKING_PROPERTY_REVIEW_REQUESTED,
  TRACKING_PROPERTY_ASSIGNED_TO_YOU,
} from '~/homepage/tracking_constants';
import { withItems, withoutItems } from './mocks/merge_requests_widget_metadata_query_mocks';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('MergeRequestsWidget', () => {
  Vue.use(VueApollo);

  const MOCK_DUO_CODE_REVIEW_BOT_USERNAME = 'GitLabDuo';
  const MOCK_REVIEW_REQUESTED_PATH = '/review/requested/path';
  const MOCK_ASSIGNED_TO_YOU_PATH = '/assigned/to/you/path';
  const MOCK_CURRENT_TIME = new Date('2025-06-12T18:13:25Z');

  useFakeDate(MOCK_CURRENT_TIME);

  const mergeRequestsWidgetMetadataQuerySuccessHandler = (data) =>
    jest.fn().mockResolvedValue(data);

  let wrapper;

  const findBaseWidget = () => wrapper.findComponent(BaseWidget);
  const findReviewRequestedCard = () => wrapper.findAllComponents(GlLink).at(0);
  const findAssignedToYouCard = () => wrapper.findAllComponents(GlLink).at(1);
  const findReviewRequestedCount = () => wrapper.findByTestId('review-requested-count');
  const findReviewRequestedLastUpdatedAt = () =>
    wrapper.findByTestId('review-requested-last-updated-at');
  const findAssignedCount = () => wrapper.findByTestId('assigned-count');
  const findAssignedLastUpdatedAt = () => wrapper.findByTestId('assigned-last-updated-at');

  afterEach(() => {
    jest.restoreAllMocks();
  });

  function createWrapper({
    mergeRequestsWidgetMetadataQueryHandler = mergeRequestsWidgetMetadataQuerySuccessHandler(
      withItems,
    ),
  } = {}) {
    const mockApollo = createMockApollo([
      [mergeRequestsWidgetMetadataQuery, mergeRequestsWidgetMetadataQueryHandler],
    ]);
    wrapper = shallowMountExtended(MergeRequestsWidget, {
      apolloProvider: mockApollo,
      provide: {
        duoCodeReviewBotUsername: MOCK_DUO_CODE_REVIEW_BOT_USERNAME,
      },
      propsData: {
        reviewRequestedPath: MOCK_REVIEW_REQUESTED_PATH,
        assignedToYouPath: MOCK_ASSIGNED_TO_YOU_PATH,
      },
      stubs: {
        GlSprintf,
        BaseWidget,
      },
    });
  }

  describe('cards', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the "Review requested" card', () => {
      const card = findReviewRequestedCard();

      expect(card.exists()).toBe(true);
      expect(card.text()).toMatch('Merge requests waiting for your review');
    });

    it('renders the "Assigned to you" card', () => {
      const card = findAssignedToYouCard();

      expect(card.exists()).toBe(true);
      expect(card.text()).toMatch('Merge requests assigned to you');
    });
  });

  describe('metadata', () => {
    it("shows the counts' loading state and no timestamp until the query has resolved", () => {
      createWrapper();

      expect(findReviewRequestedLastUpdatedAt().exists()).toBe(false);
      expect(findAssignedLastUpdatedAt().exists()).toBe(false);

      expect(findReviewRequestedCount().text()).toBe('-');
      expect(findAssignedCount().text()).toBe('-');
    });

    it('shows the metadata once the query has resolved', async () => {
      createWrapper();
      await waitForPromises();

      expect(findReviewRequestedCount().text()).toBe('12');
      expect(findReviewRequestedLastUpdatedAt().text()).toBe('3 hours ago');
      expect(findAssignedCount().text()).toBe('4');
      expect(findAssignedLastUpdatedAt().text()).toBe('2 days ago');
    });

    it('shows partial metadata when the user has no relevant items', async () => {
      createWrapper({
        mergeRequestsWidgetMetadataQueryHandler:
          mergeRequestsWidgetMetadataQuerySuccessHandler(withoutItems),
      });
      await waitForPromises();

      expect(findReviewRequestedLastUpdatedAt().exists()).toBe(false);
      expect(findAssignedLastUpdatedAt().exists()).toBe(false);

      expect(findReviewRequestedCount().text()).toBe('0');
      expect(findAssignedCount().text()).toBe('0');
    });

    it('shows error messages in both cards if the query errors out', async () => {
      createWrapper({
        mergeRequestsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
      });
      await waitForPromises();

      expect(findReviewRequestedCard().text()).toContain(
        'The number of merge requests is not available. Please refresh the page to try again, or visit the dashboard.',
      );
      expect(findAssignedToYouCard().text()).toContain(
        'The number of merge requests is not available. Please refresh the page to try again, or visit the dashboard.',
      );
      expect(Sentry.captureException).toHaveBeenCalled();

      expect(findReviewRequestedCard().text()).not.toMatch(
        'Merge requests waiting for your review',
      );
      expect(findAssignedToYouCard().text()).not.toMatch('Merge requests assigned to you');
    });

    it('shows error icons in both cards when in error state', async () => {
      createWrapper({
        mergeRequestsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
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
      const mergeRequestsWidgetMetadataQueryHandler =
        mergeRequestsWidgetMetadataQuerySuccessHandler(withItems);

      createWrapper({ mergeRequestsWidgetMetadataQueryHandler });
      await waitForPromises();

      // queried on initial mount
      expect(mergeRequestsWidgetMetadataQueryHandler).toHaveBeenCalledTimes(1);

      const baseWidget = findBaseWidget();
      baseWidget.vm.$emit('visible');

      await waitForPromises();

      // queried after visibility change
      expect(mergeRequestsWidgetMetadataQueryHandler).toHaveBeenCalledTimes(2);
    });
  });

  describe('number formatting', () => {
    it('formats large counts using formatCount', async () => {
      const mockData = {
        data: {
          currentUser: {
            id: 'gid://gitlab/User/1',
            reviewRequestedMergeRequests: {
              count: 25000,
              nodes: [
                {
                  id: 'gid://gitlab/MergeRequest/1',
                  updatedAt: '2025-06-11T18:13:25Z',
                  __typename: 'MergeRequest',
                },
              ],
              __typename: 'MergeRequestConnection',
            },
            assignedMergeRequests: {
              count: 750000,
              nodes: [
                {
                  id: 'gid://gitlab/MergeRequest/2',
                  updatedAt: '2025-06-10T18:13:25Z',
                  __typename: 'MergeRequest',
                },
              ],
              __typename: 'MergeRequestConnection',
            },
            __typename: 'CurrentUser',
          },
        },
      };

      createWrapper({
        mergeRequestsWidgetMetadataQueryHandler:
          mergeRequestsWidgetMetadataQuerySuccessHandler(mockData),
      });
      await waitForPromises();

      expect(findReviewRequestedCount().text()).toBe('25K');
      expect(findAssignedCount().text()).toBe('750K');
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('tracks click on "Review requested" card', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const reviewRequestedCard = findReviewRequestedCard();

      reviewRequestedCard.vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_MERGE_REQUESTS,
          property: TRACKING_PROPERTY_REVIEW_REQUESTED,
        },
        undefined,
      );
    });

    it('tracks click on "Assigned to you" card', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const assignedCard = findAssignedToYouCard();

      assignedCard.vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_MERGE_REQUESTS,
          property: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
        },
        undefined,
      );
    });
  });
});
