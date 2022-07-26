import { shallowMount } from '@vue/test-utils';
import simplePoll from '~/lib/utils/simple_poll';
import MrWidgetMerging from '~/vue_merge_request_widget/components/states/mr_widget_merging.vue';

jest.mock('~/lib/utils/simple_poll', () =>
  jest.fn().mockImplementation(jest.requireActual('~/lib/utils/simple_poll').default),
);

describe('MRWidgetMerging', () => {
  let wrapper;

  const GlEmoji = { template: '<img />' };
  beforeEach(() => {
    wrapper = shallowMount(MrWidgetMerging, {
      propsData: {
        mr: {
          targetBranchPath: '/branch-path',
          targetBranch: 'branch',
          transitionStateMachine() {},
        },
        service: {
          poll: jest.fn().mockResolvedValue(),
        },
      },
      stubs: {
        GlEmoji,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders information about merge request being merged', () => {
    expect(
      wrapper
        .find('.media-body')
        .text()
        .trim()
        .replace(/\s\s+/g, ' ')
        .replace(/[\r\n]+/g, ' '),
    ).toContain('Merging!');
  });

  describe('initiateMergePolling', () => {
    it('should call simplePoll', () => {
      wrapper.vm.initiateMergePolling();

      expect(simplePoll).toHaveBeenCalledWith(expect.any(Function), { timeout: 0 });
    });

    it('should call handleMergePolling', () => {
      jest.spyOn(wrapper.vm, 'handleMergePolling').mockImplementation(() => {});

      wrapper.vm.initiateMergePolling();

      expect(wrapper.vm.handleMergePolling).toHaveBeenCalled();
    });
  });
});
