import { shallowMount } from '@vue/test-utils';
import MergeChecksFailed from '~/vue_merge_request_widget/components/states/merge_checks_failed.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = shallowMount(MergeChecksFailed, {
    propsData,
  });
}

describe('Merge request widget merge checks failed state component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    mrState                                   | displayText
    ${{ isPipelineFailed: true }}             | ${'pipelineFailed'}
    ${{ approvals: true, isApproved: false }} | ${'approvalNeeded'}
    ${{ hasMergeableDiscussionsState: true }} | ${'unresolvedDiscussions'}
  `('display $displayText text for $mrState', ({ mrState, displayText }) => {
    factory({ mr: mrState });

    expect(wrapper.text()).toContain(MergeChecksFailed.i18n[displayText]);
  });

  describe('unresolved discussions', () => {
    it('renders jump to button', () => {
      factory({ mr: { hasMergeableDiscussionsState: true } });

      expect(wrapper.find('[data-testid="jumpToUnresolved"]').exists()).toBe(true);
    });

    it('renders resolve thread button', () => {
      factory({
        mr: {
          hasMergeableDiscussionsState: true,
          createIssueToResolveDiscussionsPath: 'https://gitlab.com',
        },
      });

      expect(wrapper.find('[data-testid="resolveIssue"]').exists()).toBe(true);
      expect(wrapper.find('[data-testid="resolveIssue"]').attributes('href')).toBe(
        'https://gitlab.com',
      );
    });
  });
});
