import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import BlobHeaderViewerSwitcher from '~/blob/components/blob_header_viewer_switcher.vue';
import {
  RICH_BLOB_VIEWER,
  RICH_BLOB_VIEWER_TITLE,
  SIMPLE_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
} from '~/blob/components/constants';

describe('Blob Header Viewer Switcher', () => {
  let wrapper;
  let trackingSpy;

  function createComponent(propsData = { showViewerToggles: true }, featureFlag = false) {
    wrapper = mountExtended(BlobHeaderViewerSwitcher, {
      propsData,
      provide: {
        glFeatures: { blobOverflowMenu: featureFlag },
      },
    });
  }

  const findSimpleViewerButton = () => wrapper.findComponent('[data-viewer="simple"]');
  const findRichViewerButton = () => wrapper.findComponent('[data-viewer="rich"]');
  const findBlameButton = () => wrapper.findByText('Blame');

  describe('initialization', () => {
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
      createComponent({ value: RICH_BLOB_VIEWER, showViewerToggles: true });

      findSimpleViewerButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('input')).toEqual([[SIMPLE_BLOB_VIEWER]]);
    });
  });

  it('does not render simple and rich viewer buttons if `showViewerToggles` is `false`', () => {
    createComponent({ showViewerToggles: false });

    expect(findSimpleViewerButton().exists()).toBe(false);
    expect(findRichViewerButton().exists()).toBe(false);
  });

  it('does not render a Blame button if `showBlameToggle` is `false`', async () => {
    createComponent({ showBlameToggle: false });
    await nextTick();

    expect(findBlameButton().exists()).toBe(false);
  });

  it('emits an event when the Blame button is clicked', async () => {
    createComponent({ showBlameToggle: true });

    findBlameButton().trigger('click');
    await nextTick();

    expect(wrapper.emitted('blame')).toHaveLength(1);
  });

  it('emits a tracking event when the Blame button is clicked', async () => {
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    createComponent({ showBlameToggle: true });

    findBlameButton().trigger('click');
    await nextTick();

    expect(trackingSpy).toHaveBeenCalledWith(
      undefined,
      'open_blame_viewer_on_blob_page',
      expect.any(Object),
    );
  });

  describe('with blobOverflowMenu feature flag', () => {
    it('renders icon toggles, when flag is disabled', () => {
      createComponent();

      expect(findSimpleViewerButton().props('icon')).toBe('code');
      expect(findSimpleViewerButton().text()).toBe('');
      expect(findRichViewerButton().props('icon')).toBe('document');
      expect(findRichViewerButton().text()).toBe('');
    });

    it('renders text toggles, when flag is enabled', () => {
      createComponent({ showViewerToggles: true }, true);

      expect(findSimpleViewerButton().props('icon')).toBe('');
      expect(findSimpleViewerButton().text()).toBe('Code');
      expect(findRichViewerButton().props('icon')).toBe('');
      expect(findRichViewerButton().text()).toBe('Preview');
    });
  });
});
