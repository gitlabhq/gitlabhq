import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssueCardStatistics from '~/issues/list/components/issue_card_statistics.vue';
import { i18n } from '~/issues/list/constants';

describe('IssueCardStatistics CE component', () => {
  let wrapper;

  const findMergeRequests = () => wrapper.findByTestId('merge-requests');
  const findUpvotes = () => wrapper.findByTestId('issuable-upvotes');
  const findDownvotes = () => wrapper.findByTestId('issuable-downvotes');

  const mountComponent = ({ mergeRequestsCount, upvotes, downvotes } = {}) => {
    wrapper = shallowMountExtended(IssueCardStatistics, {
      propsData: {
        issue: {
          mergeRequestsCount,
          upvotes,
          downvotes,
        },
      },
    });
  };

  describe('when issue attributes are undefined', () => {
    it('does not render the attributes', () => {
      mountComponent();

      expect(findMergeRequests().exists()).toBe(false);
      expect(findUpvotes().exists()).toBe(false);
      expect(findDownvotes().exists()).toBe(false);
    });
  });

  describe('when issue attributes are defined', () => {
    beforeEach(() => {
      mountComponent({ mergeRequestsCount: 1, upvotes: 5, downvotes: 9 });
    });

    it('renders merge requests', () => {
      const mergeRequests = findMergeRequests();

      expect(mergeRequests.text()).toBe('1');
      expect(mergeRequests.attributes('title')).toBe(i18n.relatedMergeRequests);
      expect(mergeRequests.findComponent(GlIcon).props('name')).toBe('merge-request');
    });

    it('renders upvotes', () => {
      const upvotes = findUpvotes();

      expect(upvotes.text()).toBe('5');
      expect(upvotes.attributes('title')).toBe(i18n.upvotes);
      expect(upvotes.findComponent(GlIcon).props('name')).toBe('thumb-up');
    });

    it('renders downvotes', () => {
      const downvotes = findDownvotes();

      expect(downvotes.text()).toBe('9');
      expect(downvotes.attributes('title')).toBe(i18n.downvotes);
      expect(downvotes.findComponent(GlIcon).props('name')).toBe('thumb-down');
    });
  });
});
