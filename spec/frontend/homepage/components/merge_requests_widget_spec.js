import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import MergeRequestsWidget from '~/homepage/components/merge_requests_widget.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import mergeRequestsWidgetMetadataQuery from '~/homepage/graphql/queries/merge_requests_widget_metadata.query.graphql';
import VisibilityChangeDetector from '~/homepage/components/visibility_change_detector.vue';
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

  const findLinksList = () => wrapper.findByTestId('links-list');
  const findErrorMessage = () => wrapper.findByTestId('error-message');
  const findGlLinks = () => wrapper.findAllComponents(GlLink);
  const findReviewRequestedLink = () => findGlLinks().at(0);
  const findAssignedToYouLink = () => findGlLinks().at(1);
  const findReviewRequestedCount = () => wrapper.findByTestId('review-requested-count');
  const findReviewRequestedLastUpdatedAt = () =>
    wrapper.findByTestId('review-requested-last-updated-at');
  const findAssignedCount = () => wrapper.findByTestId('assigned-count');
  const findAssignedLastUpdatedAt = () => wrapper.findByTestId('assigned-last-updated-at');
  const findDetector = () => wrapper.findComponent(VisibilityChangeDetector);

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
      provide: { duoCodeReviewBotUsername: MOCK_DUO_CODE_REVIEW_BOT_USERNAME },
      propsData: {
        reviewRequestedPath: MOCK_REVIEW_REQUESTED_PATH,
        assignedToYouPath: MOCK_ASSIGNED_TO_YOU_PATH,
      },
      stubs: {
        GlSprintf,
      },
    });
  }

  describe('links', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the "Review requested" link', () => {
      expect(findGlLinks().at(0).props('href')).toBe(MOCK_REVIEW_REQUESTED_PATH);
    });

    it('renders the "Assigned to you" link', () => {
      expect(findGlLinks().at(1).props('href')).toBe(MOCK_ASSIGNED_TO_YOU_PATH);
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

    it('shows an error message if the query errors out', async () => {
      createWrapper({
        mergeRequestsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
      });
      await waitForPromises();

      expect(findErrorMessage().text()).toBe(
        'The number of merge requests is not available. Please refresh the page to try again, or visit the dashboard.',
      );
      expect(findErrorMessage().findComponent(GlLink).props('href')).toBe(
        MOCK_ASSIGNED_TO_YOU_PATH,
      );
      expect(Sentry.captureException).toHaveBeenCalled();
      expect(findLinksList().exists()).toBe(false);
    });
  });

  describe('refresh functionality', () => {
    it('refreshes on becoming visible again', async () => {
      const reloadSpy = jest
        .spyOn(MergeRequestsWidget.methods, 'reload')
        .mockImplementation(() => {});

      createWrapper();
      await waitForPromises();
      reloadSpy.mockClear();

      findDetector().vm.$emit('visible');
      await waitForPromises();

      expect(reloadSpy).toHaveBeenCalled();
      reloadSpy.mockRestore();
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('tracks click on "Review requested" link', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const reviewRequestedLink = findReviewRequestedLink();

      reviewRequestedLink.vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_MERGE_REQUESTS,
          property: TRACKING_PROPERTY_REVIEW_REQUESTED,
        },
        undefined,
      );
    });

    it('tracks click on "Assigned to you" link', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const assignedLink = findAssignedToYouLink();

      assignedLink.vm.$emit('click');

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
