import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssueCardStatistics from '~/issues/list/components/issue_card_statistics.vue';

describe('IssueCardStatistics CE component', () => {
  let wrapper;

  const findMergeRequests = () => wrapper.findByTestId('merge-requests');
  const findUpvotes = () => wrapper.findByTestId('issuable-upvotes');
  const findDownvotes = () => wrapper.findByTestId('issuable-downvotes');

  const mountComponent = (issue = {}) => {
    wrapper = shallowMountExtended(IssueCardStatistics, {
      propsData: {
        issue,
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
    const issue = { mergeRequestsCount: 1, upvotes: 5, downvotes: 9 };
    beforeEach(() => {
      mountComponent(issue);
    });

    it('renders merge requests', () => {
      const mergeRequests = findMergeRequests();

      expect(mergeRequests.text()).toBe('1');
      expect(mergeRequests.attributes('title')).toBe('Related merge requests');
      expect(mergeRequests.findComponent(GlIcon).props('name')).toBe('merge-request');
    });

    it('renders upvotes', () => {
      const upvotes = findUpvotes();

      expect(upvotes.text()).toBe('5');
      expect(upvotes.attributes('title')).toBe('Upvotes');
      expect(upvotes.findComponent(GlIcon).props('name')).toBe('thumb-up');
    });

    it('renders downvotes', () => {
      const downvotes = findDownvotes();

      expect(downvotes.text()).toBe('9');
      expect(downvotes.attributes('title')).toBe('Downvotes');
      expect(downvotes.findComponent(GlIcon).props('name')).toBe('thumb-down');
    });
  });

  describe('with work item object', () => {
    it('renders upvotes and downvotes', () => {
      const issue = {
        widgets: [{ type: 'AWARD_EMOJI', downvotes: '4', upvotes: '8' }],
      };
      mountComponent(issue);

      expect(findDownvotes().text()).toBe('4');
      expect(findUpvotes().text()).toBe('8');
    });
  });
});
