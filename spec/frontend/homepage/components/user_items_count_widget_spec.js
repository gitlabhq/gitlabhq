import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeDate } from 'helpers/fake_date';
import BaseWidget from '~/homepage/components/base_widget.vue';
import UserItemsCountWidget from '~/homepage/components/user_items_count_widget.vue';
import {
  mergeRequestsDataWithItems,
  mergeRequestsDataWithoutItems,
  mergeRequestsDataWithHugeCount,
} from './mocks/merge_requests_widget_metadata_query_mocks';

describe('UserItemsCountWidget', () => {
  const MOCK_DUO_CODE_REVIEW_BOT_USERNAME = 'GitLabDuo';
  const MOCK_PATH = '/merge/requests/review/requested/path';
  const MOCK_ARIA_LABEL = 'Merge requests with review requested';
  const MOCK_ERROR_TEXT =
    'The number of merge requests is not available. Please refresh the page to try again, or visit the dashboard.';
  const MOCK_LINK_TEXT = 'Merge requests waiting for your review';
  const MOCK_CURRENT_TIME = new Date('2025-06-12T18:13:25Z');

  useFakeDate(MOCK_CURRENT_TIME);

  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);
  const findCount = () => wrapper.findByTestId('count');
  const findLastUpdatedAt = () => wrapper.findByTestId('last-updated-at');

  function createWrapper(props = {}) {
    wrapper = shallowMountExtended(UserItemsCountWidget, {
      provide: {
        duoCodeReviewBotUsername: MOCK_DUO_CODE_REVIEW_BOT_USERNAME,
      },
      propsData: {
        hasError: false,
        path: MOCK_PATH,
        linkAriaLabel: MOCK_ARIA_LABEL,
        errorText: MOCK_ERROR_TEXT,
        linkText: MOCK_LINK_TEXT,
        userItems: mergeRequestsDataWithItems.data.currentUser.reviewRequestedMergeRequests,
        ...props,
      },
      stubs: {
        GlSprintf,
        BaseWidget,
      },
    });
  }

  describe('with valid data', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the metadata', () => {
      expect(findCount().text()).toBe('12');
      expect(findLastUpdatedAt().text()).toBe('3 hours ago');
    });

    it('formats large counts using formatCount', async () => {
      createWrapper({
        userItems: mergeRequestsDataWithHugeCount.data.currentUser.reviewRequestedMergeRequests,
      });
      await waitForPromises();

      expect(findCount().text()).toBe('750K');
    });

    it('tracks click on card', () => {
      findLink().vm.$emit('click');

      expect(wrapper.emitted('click-link')).toHaveLength(1);
    });
  });

  describe('with missing data', () => {
    it("shows the counts' loading state and no timestamp when workitems is null", () => {
      createWrapper({ userItems: null });

      expect(findLastUpdatedAt().exists()).toBe(false);

      expect(findCount().text()).toBe('-');
    });

    it('shows partial metadata when the user has no relevant items', () => {
      createWrapper({
        userItems: mergeRequestsDataWithoutItems.data.currentUser.reviewRequestedMergeRequests,
      });

      expect(findLastUpdatedAt().exists()).toBe(false);

      expect(findCount().text()).toBe('0');
    });
  });

  describe('with error', () => {
    it('shows error message', () => {
      createWrapper({ hasError: true });

      expect(findLink().text()).toContain(MOCK_ERROR_TEXT);

      expect(findLink().text()).not.toMatch(MOCK_LINK_TEXT);
    });

    it('shows error icon', () => {
      createWrapper({ hasError: true });

      const errorIcon = wrapper.findComponent({ name: 'GlIcon' });

      expect(errorIcon.exists()).toBe(true);
    });
  });
});
