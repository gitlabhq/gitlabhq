import { nextTick } from 'vue';
import { GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FileTreeBrowserPopover from '~/repository/file_tree_browser/components/file_tree_browser_popover.vue';

describe('FileTreeBrowserPopover', () => {
  let wrapper;

  const findPopover = () => wrapper.findComponent(GlPopover);

  const createComponent = (props = {}) => {
    const mockElement = document.createElement('button');
    wrapper = shallowMount(FileTreeBrowserPopover, {
      propsData: {
        targetElement: mockElement,
        ...props,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(global, 'clearTimeout').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has correct default props', () => {
      expect(findPopover().props()).toMatchObject({
        boundary: 'viewport',
        placement: 'bottom',
        show: false,
        showCloseButton: true,
        triggers: 'manual',
      });
    });

    it('is shown after 500ms delay', async () => {
      jest.advanceTimersByTime(500);
      await nextTick();

      expect(findPopover().props('show')).toBe(true);
    });

    it('hides after 6000ms', async () => {
      jest.advanceTimersByTime(500);
      await nextTick();
      expect(findPopover().props('show')).toBe(true);

      jest.advanceTimersByTime(6000);
      await nextTick();

      expect(findPopover().props('show')).toBe(false);
    });
  });

  describe('when dismissing the popover via close button', () => {
    beforeEach(async () => {
      createComponent({ shouldShow: true });

      jest.advanceTimersByTime(500);
      await nextTick();

      findPopover().vm.$emit('hidden');
      await nextTick();
    });

    it('emits dismiss event', () => {
      expect(wrapper.emitted('dismiss')).toEqual([[]]);
    });
  });

  describe('when hovering over target element', () => {
    beforeEach(async () => {
      createComponent({ shouldShow: true });

      jest.advanceTimersByTime(500);
      await nextTick();
    });

    it('hides the popover on mouseenter', async () => {
      const targetElement = wrapper.props('targetElement');
      const event = new MouseEvent('mouseenter');
      targetElement.dispatchEvent(event);

      await nextTick();

      expect(findPopover().props('show')).toBe(false);
    });
  });

  describe('when focusing on target element', () => {
    beforeEach(async () => {
      createComponent({ shouldShow: true });

      jest.advanceTimersByTime(500);
      await nextTick();
    });

    it('hides the popover on mouseenter', async () => {
      const targetElement = wrapper.props('targetElement');
      const event = new MouseEvent('focus');
      targetElement.dispatchEvent(event);

      await nextTick();

      expect(findPopover().props('show')).toBe(false);
    });
  });

  describe('cleanup', () => {
    it('clears timeouts on destroy', async () => {
      createComponent({ shouldShow: true });
      jest.advanceTimersByTime(500);
      await nextTick();

      wrapper.destroy();

      expect(global.clearTimeout).toHaveBeenCalled();
    });

    it('removes listeners on destroy', async () => {
      const mockElement = document.createElement('button');
      const removeEventListenerSpy = jest.spyOn(mockElement, 'removeEventListener');

      wrapper = shallowMount(FileTreeBrowserPopover, {
        propsData: {
          targetElement: mockElement,
          shouldShow: true,
        },
      });

      jest.advanceTimersByTime(500);
      await nextTick();

      wrapper.destroy();

      expect(removeEventListenerSpy).toHaveBeenCalledWith('mouseenter', expect.any(Function));
      expect(removeEventListenerSpy).toHaveBeenCalledWith('focus', expect.any(Function));
      removeEventListenerSpy.mockRestore();
    });
  });
});
