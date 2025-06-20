import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import MergeRequestsWidget from '~/homepage/components/merge_requests_widget.vue';
import mergeRequestsWidgetMetadataQuery from '~/homepage/graphql/queries/merge_requests_widget_metadata.query.graphql';
import { withItems, withoutItems } from './mocks/merge_requests_widget_metadata_query_mocks';

describe('MergeRequestsWidget', () => {
  Vue.use(VueApollo);

  const MOCK_REVIEW_REQUESTED_PATH = '/review/requested/path';
  const MOCK_ASSIGNED_TO_YOU_PATH = '/assigned/to/you/path';
  const MOCK_CURRENT_TIME = new Date('2025-06-12T18:13:25Z');

  useFakeDate(MOCK_CURRENT_TIME);

  const mergeRequestsWidgetMetadataQueryHandler = (data) => jest.fn().mockResolvedValue(data);

  let wrapper;

  const findGlLinks = () => wrapper.findAllComponents(GlLink);
  const findReviewRequestedCount = () => wrapper.findByTestId('review-requested-count');
  const findReviewRequestedLastUpdatedAt = () =>
    wrapper.findByTestId('review-requested-last-updated-at');
  const findAssignedCount = () => wrapper.findByTestId('assigned-count');
  const findAssignedLastUpdatedAt = () => wrapper.findByTestId('assigned-last-updated-at');

  function createWrapper({ mergeRequestsWidgetMetadataQueryMock = withItems } = {}) {
    const mockApollo = createMockApollo([
      [
        mergeRequestsWidgetMetadataQuery,
        mergeRequestsWidgetMetadataQueryHandler(mergeRequestsWidgetMetadataQueryMock),
      ],
    ]);
    wrapper = shallowMountExtended(MergeRequestsWidget, {
      apolloProvider: mockApollo,
      propsData: {
        reviewRequestedPath: MOCK_REVIEW_REQUESTED_PATH,
        assignedToYouPath: MOCK_ASSIGNED_TO_YOU_PATH,
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
    it('does not show any metadata until the query has resolved', () => {
      createWrapper();

      expect(findReviewRequestedCount().exists()).toBe(false);
      expect(findReviewRequestedLastUpdatedAt().exists()).toBe(false);
      expect(findAssignedCount().exists()).toBe(false);
      expect(findAssignedLastUpdatedAt().exists()).toBe(false);
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
      createWrapper({ mergeRequestsWidgetMetadataQueryMock: withoutItems });
      await waitForPromises();

      expect(findReviewRequestedCount().exists()).toBe(true);
      expect(findReviewRequestedLastUpdatedAt().exists()).toBe(false);
      expect(findAssignedCount().exists()).toBe(true);
      expect(findAssignedLastUpdatedAt().exists()).toBe(false);

      expect(findReviewRequestedCount().text()).toBe('0');
      expect(findAssignedCount().text()).toBe('0');
    });
  });
});
