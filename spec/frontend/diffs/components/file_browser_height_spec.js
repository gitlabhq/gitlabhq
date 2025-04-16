import Vue, { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import StickyViewportFillerHeight from '~/diffs/components/sticky_viewport_filler_height.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import { observeElementOnce } from '~/lib/utils/dom_utils';

jest.mock('~/lib/utils/dom_utils');

Vue.use(PiniaVuePlugin);

describe('FileBrowserHeight', () => {
  let wrapper;
  let pinia;
  let screenChangeCallback;

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
    jest.spyOn(window, 'matchMedia').mockReturnValue({
      matches,
      addEventListener: jest.fn((_, callback) => {
        screenChangeCallback = callback;
      }),
      removeEventListener: jest.fn(),
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
      screenChangeCallback({ matches: true });
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

    it('updates bottom offset when review bar is shown', async () => {
      const reviewBarHeight = 50;
      let callback;
      useBatchComments().drafts = [{}];
      useBatchComments().reviewBarRendered = true;
      observeElementOnce.mockImplementation((element, cb) => {
        callback = cb;
      });
      createComponent();
      callback([{ boundingClientRect: { height: reviewBarHeight } }]);
      await nextTick();
      const filler = wrapper.findComponent(StickyViewportFillerHeight);
      expect(filler.props('stickyBottomOffset')).toBe(bottomPadding + reviewBarHeight);
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
      screenChangeCallback({ matches: false });
      await nextTick();
      expect(wrapper.findComponent(StickyViewportFillerHeight).exists()).toBe(true);
      expect(findSlotContent().exists()).toBe(true);
    });
  });
});
