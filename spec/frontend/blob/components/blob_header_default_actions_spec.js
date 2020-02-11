import { mount } from '@vue/test-utils';
import BlobHeaderActions from '~/blob/components/blob_header_default_actions.vue';
import {
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_RAW_TITLE,
  RICH_BLOB_VIEWER,
} from '~/blob/components/constants';
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { Blob } from './mock_data';
import eventHub from '~/blob/event_hub';

describe('Blob Header Default Actions', () => {
  let wrapper;
  let btnGroup;
  let buttons;
  const hrefPrefix = 'http://localhost';

  function createComponent(blobProps = {}, propsData = {}) {
    wrapper = mount(BlobHeaderActions, {
      propsData: {
        blob: Object.assign({}, Blob, blobProps),
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
      expect(buttons.at(1).vm.$el.href).toBe(`${hrefPrefix}${Blob.rawPath}`);
    });

    it('correct href attribute on Download button', () => {
      expect(buttons.at(2).vm.$el.href).toBe(`${hrefPrefix}${Blob.rawPath}?inline=false`);
    });

    it('does not render "Copy file contents" button as disables if the viewer is Simple', () => {
      expect(buttons.at(0).attributes('disabled')).toBeUndefined();
    });

    it('renders "Copy file contents" button as disables if the viewer is Rich', () => {
      createComponent(
        {},
        {
          activeViewer: RICH_BLOB_VIEWER,
        },
      );
      buttons = wrapper.findAll(GlButton);

      expect(buttons.at(0).attributes('disabled')).toBeTruthy();
    });
  });

  describe('functionally', () => {
    it('emits an event when a Copy Contents button is clicked', () => {
      jest.spyOn(eventHub, '$emit');
      buttons.at(0).vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith('copy');
    });
  });
});
