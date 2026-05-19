import { GlPopover } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InlineBlamePopover from '~/blob/components/inline_blame_popover.vue';

describe('InlineBlamePopover', () => {
  let wrapper;
  let targetElement;
  let observe;
  let disconnect;
  let intersectionObserverCallback;
  let resizeObserve;
  let resizeDisconnect;

  const findPopover = () => wrapper.findComponent(GlPopover);

  const createComponent = () => {
    targetElement = document.createElement('button');
    wrapper = shallowMountExtended(InlineBlamePopover, {
      propsData: { targetElement: () => targetElement },
    });
  };

  beforeEach(() => {
    observe = jest.fn();
    disconnect = jest.fn();
    window.IntersectionObserver = jest.fn((callback) => {
      intersectionObserverCallback = callback;
      return { observe, disconnect, unobserve: jest.fn() };
    });

    resizeObserve = jest.fn();
    resizeDisconnect = jest.fn();
    window.ResizeObserver = jest.fn(() => ({
      observe: resizeObserve,
      disconnect: resizeDisconnect,
    }));
  });

  it('renders a popover anchored to the target element with the expected copy', () => {
    createComponent();
    const popover = findPopover();

    expect(popover.props()).toMatchObject({
      show: true,
      placement: 'bottom',
      triggers: 'manual',
      title: 'Blame is now in page',
      cssClasses: 'gl-z-200',
    });
    expect(popover.props('target')).toBe(targetElement);
  });

  it('observes the target element for viewport intersections', () => {
    createComponent();

    expect(observe).toHaveBeenCalledWith(targetElement);
  });

  it('hides the popover when the target leaves the viewport', async () => {
    createComponent();

    intersectionObserverCallback([{ isIntersecting: false }]);
    await nextTick();

    expect(findPopover().props('show')).toBe(false);
  });

  it('emits `dismiss` when the popover close button is clicked', () => {
    createComponent();
    findPopover().vm.$emit('close-button-clicked');

    expect(wrapper.emitted('dismiss')).toEqual([[]]);
  });

  it('emits `dismiss` when the target element is clicked', () => {
    createComponent();
    targetElement.dispatchEvent(new MouseEvent('click'));

    expect(wrapper.emitted('dismiss')).toEqual([[]]);
  });

  it('does not throw when IntersectionObserver is unavailable', () => {
    window.IntersectionObserver = undefined;

    expect(() => createComponent()).not.toThrow();
    expect(findPopover().props('show')).toBe(true);
  });

  describe('repositioning on container resize', () => {
    it('observes the content container for size changes', () => {
      createComponent();
      expect(resizeObserve).toHaveBeenCalledWith(document.body);
    });
  });

  describe('on destroy', () => {
    it('removes the click listener from the target element', () => {
      createComponent();
      const removeEventListenerSpy = jest.spyOn(targetElement, 'removeEventListener');

      wrapper.destroy();

      expect(removeEventListenerSpy).toHaveBeenCalledWith('click', expect.any(Function));
    });

    it('disconnects the intersection observer', () => {
      createComponent();
      wrapper.destroy();

      expect(disconnect).toHaveBeenCalled();
    });

    it('disconnects the resize observer and cancels pending reposition', () => {
      createComponent();
      wrapper.destroy();

      expect(resizeDisconnect).toHaveBeenCalled();
    });
  });
});
