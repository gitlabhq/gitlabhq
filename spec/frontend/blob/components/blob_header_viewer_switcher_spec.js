import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import BlobHeaderViewerSwitcher from '~/blob/components/blob_header_viewer_switcher.vue';
import {
  RICH_BLOB_VIEWER,
  RICH_BLOB_VIEWER_TITLE,
  SIMPLE_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
} from '~/blob/components/constants';

describe('Blob Header Viewer Switcher', () => {
  let wrapper;

  function createComponent(propsData = {}) {
    wrapper = mount(BlobHeaderViewerSwitcher, {
      propsData,
    });
  }

  const findSimpleViewerButton = () => wrapper.findComponent('[data-viewer="simple"]');
  const findRichViewerButton = () => wrapper.findComponent('[data-viewer="rich"]');

  describe('intiialization', () => {
    it('is initialized with simple viewer as active', () => {
      createComponent();
      expect(findSimpleViewerButton().props('selected')).toBe(true);
      expect(findRichViewerButton().props('selected')).toBe(false);
    });
  });

  describe('rendering', () => {
    let btnGroup;
    let buttons;

    beforeEach(() => {
      createComponent();
      btnGroup = wrapper.findComponent(GlButtonGroup);
      buttons = wrapper.findAllComponents(GlButton);
    });

    it('renders gl-button-group component', () => {
      expect(btnGroup.exists()).toBe(true);
    });

    it('renders exactly 2 buttons with predefined actions', () => {
      expect(buttons.length).toBe(2);
      [SIMPLE_BLOB_VIEWER_TITLE, RICH_BLOB_VIEWER_TITLE].forEach((title, i) => {
        expect(buttons.at(i).attributes('title')).toBe(title);
      });
    });
  });

  describe('viewer changes', () => {
    it('does not switch the viewer if the selected one is already active', async () => {
      createComponent();
      expect(findSimpleViewerButton().props('selected')).toBe(true);

      findSimpleViewerButton().vm.$emit('click');
      await nextTick();

      expect(findSimpleViewerButton().props('selected')).toBe(true);
      expect(wrapper.emitted('input')).toBe(undefined);
    });

    it('emits an event when a Rich Viewer button is clicked', async () => {
      createComponent();
      expect(findSimpleViewerButton().props('selected')).toBe(true);

      findRichViewerButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('input')).toEqual([[RICH_BLOB_VIEWER]]);
    });

    it('emits an event when a Simple Viewer button is clicked', async () => {
      createComponent({ value: RICH_BLOB_VIEWER });

      findSimpleViewerButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('input')).toEqual([[SIMPLE_BLOB_VIEWER]]);
    });
  });
});
