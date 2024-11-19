import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import simplePoll from '~/lib/utils/simple_poll';
import MrWidgetMerging from '~/vue_merge_request_widget/components/states/mr_widget_merging.vue';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import { STATUS_MERGED } from '~/issues/constants';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';

jest.mock('~/super_sidebar/user_counts_fetch');
jest.mock('~/lib/utils/simple_poll', () =>
  jest.fn().mockImplementation(jest.requireActual('~/lib/utils/simple_poll').default),
);

describe('MRWidgetMerging', () => {
  let wrapper;

  const pollMock = jest.fn().mockResolvedValue();

  const GlEmoji = { template: '<img />' };
  const createComponent = () => {
    wrapper = shallowMount(MrWidgetMerging, {
      propsData: {
        mr: {
          targetBranchPath: '/branch-path',
          targetBranch: 'branch',
          transitionStateMachine() {},
        },
        service: {
          poll: pollMock,
        },
      },
      stubs: {
        GlEmoji,
      },
    });
  };

  it('renders information about merge request being merged', () => {
    createComponent();

    const message = wrapper.findComponent(BoldText).props('message');
    expect(message).toContain('Merging!');
  });

  describe('initiateMergePolling', () => {
    beforeEach(createComponent);

    it('should call simplePoll', () => {
      expect(simplePoll).toHaveBeenCalledWith(expect.any(Function), { timeout: 0 });
    });

    it('should call handleMergePolling', () => {
      expect(pollMock).toHaveBeenCalled();
    });
  });

  describe('on successful merge', () => {
    it('should re-fetch user counts', async () => {
      pollMock.mockResolvedValueOnce({ data: { state: STATUS_MERGED } });
      createComponent();

      await waitForPromises();

      expect(fetchUserCounts).toHaveBeenCalled();
    });
  });
});
