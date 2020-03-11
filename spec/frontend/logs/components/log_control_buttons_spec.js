import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import LogControlButtons from '~/logs/components/log_control_buttons.vue';
import {
  canScroll,
  isScrolledToTop,
  isScrolledToBottom,
  scrollDown,
  scrollUp,
} from '~/lib/utils/scroll_utils';

jest.mock('~/lib/utils/scroll_utils');

describe('LogControlButtons', () => {
  let wrapper;

  const findScrollToTop = () => wrapper.find('.js-scroll-to-top');
  const findScrollToBottom = () => wrapper.find('.js-scroll-to-bottom');
  const findRefreshBtn = () => wrapper.find('.js-refresh-log');

  const initWrapper = () => {
    wrapper = shallowMount(LogControlButtons);
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('displays UI elements', () => {
    initWrapper();

    expect(wrapper.isVueInstance()).toBe(true);
    expect(wrapper.isEmpty()).toBe(false);

    expect(findScrollToTop().is(GlButton)).toBe(true);
    expect(findScrollToBottom().is(GlButton)).toBe(true);
    expect(findRefreshBtn().is(GlButton)).toBe(true);
  });

  it('emits a `refresh` event on click on `refresh` button', () => {
    initWrapper();

    // An `undefined` value means no event was emitted
    expect(wrapper.emitted('refresh')).toBe(undefined);

    findRefreshBtn().vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('refresh')).toHaveLength(1);
    });
  });

  describe('when scrolling actions are enabled', () => {
    beforeEach(() => {
      // mock scrolled to the middle of a long page
      canScroll.mockReturnValue(true);
      isScrolledToBottom.mockReturnValue(false);
      isScrolledToTop.mockReturnValue(false);

      initWrapper();
      wrapper.vm.update();
      return wrapper.vm.$nextTick();
    });

    afterEach(() => {
      canScroll.mockReset();
      isScrolledToTop.mockReset();
      isScrolledToBottom.mockReset();
    });

    it('click on "scroll to top" scrolls up', () => {
      expect(findScrollToTop().is('[disabled]')).toBe(false);

      findScrollToTop().vm.$emit('click');

      expect(scrollUp).toHaveBeenCalledTimes(1);
    });

    it('click on "scroll to bottom" scrolls down', () => {
      expect(findScrollToBottom().is('[disabled]')).toBe(false);

      findScrollToBottom().vm.$emit('click');

      expect(scrollDown).toHaveBeenCalledTimes(1); // plus one time when trace was loaded
    });
  });

  describe('when scrolling actions are disabled', () => {
    beforeEach(() => {
      // mock a short page without a scrollbar
      canScroll.mockReturnValue(false);
      isScrolledToBottom.mockReturnValue(true);
      isScrolledToTop.mockReturnValue(true);

      initWrapper();
    });

    it('buttons are disabled', () => {
      wrapper.vm.update();
      return wrapper.vm.$nextTick(() => {
        expect(findScrollToTop().is('[disabled]')).toBe(true);
        expect(findScrollToBottom().is('[disabled]')).toBe(true);
      });
    });
  });
});
