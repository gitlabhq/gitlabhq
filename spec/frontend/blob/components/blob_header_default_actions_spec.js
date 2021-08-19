import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import BlobHeaderActions from '~/blob/components/blob_header_default_actions.vue';
import {
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_RAW_TITLE,
  RICH_BLOB_VIEWER,
} from '~/blob/components/constants';
import { Blob } from './mock_data';

describe('Blob Header Default Actions', () => {
  let wrapper;
  let btnGroup;
  let buttons;

  const blobHash = 'foo-bar';

  function createComponent(propsData = {}) {
    wrapper = mount(BlobHeaderActions, {
      provide: {
        blobHash,
      },
      propsData: {
        rawPath: Blob.rawPath,
        ...propsData,
      },
    });
  }

  beforeEach(() => {
    createComponent();
    btnGroup = wrapper.find(GlButtonGroup);
    buttons = wrapper.findAll(GlButton);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders', () => {
    const findCopyButton = () => wrapper.find('[data-testid="copyContentsButton"]');
    const findViewRawButton = () => wrapper.find('[data-testid="viewRawButton"]');

    it('gl-button-group component', () => {
      expect(btnGroup.exists()).toBe(true);
    });

    it('exactly 3 buttons with predefined actions', () => {
      expect(buttons.length).toBe(3);
      [BTN_COPY_CONTENTS_TITLE, BTN_RAW_TITLE, BTN_DOWNLOAD_TITLE].forEach((title, i) => {
        expect(buttons.at(i).vm.$el.title).toBe(title);
      });
    });

    it('correct href attribute on RAW button', () => {
      expect(buttons.at(1).attributes('href')).toBe(Blob.rawPath);
    });

    it('correct href attribute on Download button', () => {
      expect(buttons.at(2).attributes('href')).toBe(`${Blob.rawPath}?inline=false`);
    });

    it('does not render "Copy file contents" button as disables if the viewer is Simple', () => {
      expect(buttons.at(0).attributes('disabled')).toBeUndefined();
    });

    it('renders "Copy file contents" button as disables if the viewer is Rich', () => {
      createComponent({
        activeViewer: RICH_BLOB_VIEWER,
      });
      buttons = wrapper.findAll(GlButton);

      expect(buttons.at(0).attributes('disabled')).toBeTruthy();
    });

    it('does not render the copy button if a rendering error is set', () => {
      createComponent({
        hasRenderError: true,
      });

      expect(findCopyButton().exists()).toBe(false);
    });

    it('does not render the copy and view raw button if isBinary is set to true', () => {
      createComponent({ isBinary: true });

      expect(findCopyButton().exists()).toBe(false);
      expect(findViewRawButton().exists()).toBe(false);
    });
  });
});
