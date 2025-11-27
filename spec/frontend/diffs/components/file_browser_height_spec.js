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

jest.mock('~/lib/utils/dom_utils');

Vue.use(PiniaVuePlugin);

describe('FileBrowserHeight', () => {
  let wrapper;
  let pinia;

  const minHeight = 300;
  const topPadding = 16;
  const bottomPadding = 16;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(FileBrowserHeight, {
      pinia,
      slots: { default: `<div id="slotContent"></div>` },
      propsData,
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

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    useBatchComments();
    setCssProperties();
  });

  describe('enableStickyHeight prop', () => {
    it.each`
      enableStickyHeight | shouldExist | description
      ${true}            | ${true}     | ${'renders sticky viewport filler'}
      ${false}           | ${false}    | ${'renders plain div'}
    `(
      '$description when enableStickyHeight is $enableStickyHeight',
      ({ enableStickyHeight, shouldExist }) => {
        createComponent({ enableStickyHeight });

        expect(wrapper.findComponent(StickyViewportFillerHeight).exists()).toBe(shouldExist);
        expect(findSlotContent().exists()).toBe(true);
      },
    );

    it('sets initial props when sticky height is enabled', async () => {
      createComponent({ enableStickyHeight: true });
      await nextTick();
      const filler = wrapper.findComponent(StickyViewportFillerHeight);
      expect(filler.props('minHeight')).toBe(minHeight);
      expect(filler.props('stickyTopOffset')).toBe(topPadding);
      expect(filler.props('stickyBottomOffset')).toBe(bottomPadding);
    });
  });
});
