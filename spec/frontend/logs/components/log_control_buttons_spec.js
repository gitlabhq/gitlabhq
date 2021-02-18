import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LogControlButtons from '~/logs/components/log_control_buttons.vue';

describe('LogControlButtons', () => {
  let wrapper;

  const findScrollToTop = () => wrapper.find('.js-scroll-to-top');
  const findScrollToBottom = () => wrapper.find('.js-scroll-to-bottom');
  const findRefreshBtn = () => wrapper.find('.js-refresh-log');

  const initWrapper = (opts) => {
    wrapper = shallowMount(LogControlButtons, {
      listeners: {
        scrollUp: () => {},
        scrollDown: () => {},
      },
      ...opts,
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('displays UI elements', () => {
    initWrapper();

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
      initWrapper();
      return wrapper.vm.$nextTick();
    });

    it('click on "scroll to top" scrolls up', () => {
      expect(findScrollToTop().attributes('disabled')).toBeUndefined();

      findScrollToTop().vm.$emit('click');

      expect(wrapper.emitted('scrollUp')).toHaveLength(1);
    });

    it('click on "scroll to bottom" scrolls down', () => {
      expect(findScrollToBottom().attributes('disabled')).toBeUndefined();

      findScrollToBottom().vm.$emit('click');

      expect(wrapper.emitted('scrollDown')).toHaveLength(1);
    });
  });

  describe('when scrolling actions are disabled', () => {
    beforeEach(() => {
      initWrapper({ listeners: {} });
      return wrapper.vm.$nextTick();
    });

    it('buttons are disabled', () => {
      return wrapper.vm.$nextTick(() => {
        expect(findScrollToTop().exists()).toBe(false);
        expect(findScrollToBottom().exists()).toBe(false);
        // This should be enabled when gitlab-ui contains:
        // https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/1149
        // expect(findScrollToBottom().is('[disabled]')).toBe(true);
      });
    });
  });
});
