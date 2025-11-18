import Vue, { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import StickyViewportFillerHeight from '~/diffs/components/sticky_viewport_filler_height.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';

jest.mock('~/lib/utils/dom_utils');

Vue.use(PiniaVuePlugin);

describe('FileBrowserHeight', () => {
  let wrapper;
  let pinia;
  let breakpointChangeCallback;
  let mockBreakpointSize;

  const minHeight = 300;
  const topPadding = 16;
  const bottomPadding = 16;

  const createComponent = () => {
    wrapper = shallowMount(FileBrowserHeight, {
      pinia,
      slots: { default: `<div id="slotContent"></div>` },
    });
  };

  const findSlotContent = () => wrapper.find('#slotContent');

  const setCssProperties = () => {
    jest.spyOn(CSSStyleDeclaration.prototype, 'getPropertyValue').mockImplementation((property) => {
      if (property === 'top') return `${topPadding}px`;
      if (property === '--breakpoint-lg') return `900px`;
      if (property === '--file-tree-min-height') return `${minHeight}px`;
      if (property === '--file-tree-bottom-padding') return `${bottomPadding}px`;
      return '';
    });
  };

  const mockBreakpointInstance = (breakpointSize = 'lg') => {
    mockBreakpointSize = breakpointSize;

    jest.spyOn(PanelBreakpointInstance, 'isBreakpointDown').mockImplementation((bp) => {
      const breakpoints = ['xl', 'lg', 'md', 'sm', 'xs'];
      const currentIndex = breakpoints.indexOf(mockBreakpointSize);
      const targetIndex = breakpoints.indexOf(bp);
      return currentIndex >= targetIndex;
    });

    jest.spyOn(PanelBreakpointInstance, 'addBreakpointListener').mockImplementation((callback) => {
      breakpointChangeCallback = callback;
    });
  };

  const triggerBreakpointChange = (newBreakpoint, oldBreakpoint) => {
    mockBreakpointSize = newBreakpoint;
    breakpointChangeCallback(newBreakpoint, oldBreakpoint);
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    useBatchComments();
    setCssProperties();
  });

  describe('when screen is wide enough', () => {
    beforeEach(() => {
      mockBreakpointInstance('lg');
    });

    it('wraps contents with a sticky viewport filler height', () => {
      createComponent();
      expect(wrapper.findComponent(StickyViewportFillerHeight).exists()).toBe(true);
      expect(findSlotContent().exists()).toBe(true);
    });

    it('swaps to narrow view when breakpoint changes', async () => {
      createComponent();
      await nextTick();

      triggerBreakpointChange('sm', 'lg');
      await nextTick();

      expect(wrapper.findComponent(StickyViewportFillerHeight).exists()).toBe(false);
      expect(findSlotContent().exists()).toBe(true);
    });

    it('sets initial props', async () => {
      createComponent();
      await nextTick();
      const filler = wrapper.findComponent(StickyViewportFillerHeight);
      expect(filler.props('minHeight')).toBe(minHeight);
      expect(filler.props('stickyTopOffset')).toBe(topPadding);
      expect(filler.props('stickyBottomOffset')).toBe(bottomPadding);
    });
  });

  describe('when screen is narrow', () => {
    beforeEach(() => {
      mockBreakpointInstance('sm');
    });

    it('renders just slot content', async () => {
      createComponent();
      await nextTick();
      expect(wrapper.findComponent(StickyViewportFillerHeight).exists()).toBe(false);
      expect(findSlotContent().exists()).toBe(true);
    });

    it('swaps to widescreen view when breakpoint changes', async () => {
      createComponent();
      await nextTick();

      triggerBreakpointChange('lg', 'sm');
      await nextTick();

      expect(wrapper.findComponent(StickyViewportFillerHeight).exists()).toBe(true);
      expect(findSlotContent().exists()).toBe(true);
    });
  });

  it('unsubscribes from breakpoint changes on destroy', () => {
    const unsub = jest.spyOn(PanelBreakpointInstance, 'removeBreakpointListener');
    mockBreakpointInstance('lg');
    createComponent();

    wrapper.destroy();

    expect(unsub).toHaveBeenCalled();
  });
});
