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
  let screenChangeCallback;
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
  const mockMatchMedia = (matches = false) => {
    mockBreakpointSize = matches ? 'sm' : 'lg';
    jest
      .spyOn(PanelBreakpointInstance, 'getBreakpointSize')
      .mockImplementation(() => mockBreakpointSize);
    jest.spyOn(PanelBreakpointInstance, 'addResizeListener').mockImplementation((callback) => {
      screenChangeCallback = callback;
    });
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
      mockMatchMedia();
    });

    it('wraps contents with a sticky viewport filler height', () => {
      createComponent();
      expect(wrapper.findComponent(StickyViewportFillerHeight).exists()).toBe(true);
      expect(findSlotContent().exists()).toBe(true);
    });

    it('swaps to narrow view', async () => {
      createComponent();
      await nextTick();
      mockBreakpointSize = 'sm';
      screenChangeCallback();
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
      mockMatchMedia(true);
    });

    it('renders just slot content', async () => {
      createComponent();
      await nextTick();
      expect(wrapper.findComponent(StickyViewportFillerHeight).exists()).toBe(false);
      expect(findSlotContent().exists()).toBe(true);
    });

    it('swaps to widescreen view', async () => {
      createComponent();
      await nextTick();
      mockBreakpointSize = 'lg';
      screenChangeCallback();
      await nextTick();
      expect(wrapper.findComponent(StickyViewportFillerHeight).exists()).toBe(true);
      expect(findSlotContent().exists()).toBe(true);
    });
  });
});
