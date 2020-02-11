import { mount } from '@vue/test-utils';
import BlobHeaderViewerSwitcher from '~/blob/components/blob_header_viewer_switcher.vue';
import {
  RICH_BLOB_VIEWER,
  RICH_BLOB_VIEWER_TITLE,
  SIMPLE_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
} from '~/blob/components/constants';
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { Blob } from './mock_data';
import eventHub from '~/blob/event_hub';

describe('Blob Header Viewer Switcher', () => {
  let wrapper;

  function createComponent(blobProps = {}, propsData = {}) {
    wrapper = mount(BlobHeaderViewerSwitcher, {
      propsData: {
        blob: Object.assign({}, Blob, blobProps),
        ...propsData,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('intiialization', () => {
    it('is initialized with simple viewer as active', () => {
      createComponent();
      expect(wrapper.vm.activeViewer).toBe(SIMPLE_BLOB_VIEWER);
    });
  });

  describe('rendering', () => {
    let btnGroup;
    let buttons;

    beforeEach(() => {
      createComponent();
      btnGroup = wrapper.find(GlButtonGroup);
      buttons = wrapper.findAll(GlButton);
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
    let buttons;
    let simpleBtn;
    let richBtn;

    function factory(propsOptions = {}) {
      createComponent({}, propsOptions);
      buttons = wrapper.findAll(GlButton);
      simpleBtn = buttons.at(0);
      richBtn = buttons.at(1);

      jest.spyOn(eventHub, '$emit');
    }

    it('does not switch the viewer if the selected one is already active', () => {
      factory();
      expect(wrapper.vm.activeViewer).toBe(SIMPLE_BLOB_VIEWER);
      simpleBtn.vm.$emit('click');
      expect(wrapper.vm.activeViewer).toBe(SIMPLE_BLOB_VIEWER);
      expect(eventHub.$emit).not.toHaveBeenCalled();
    });

    it('emits an event when a Rich Viewer button is clicked', () => {
      factory();
      expect(wrapper.vm.activeViewer).toBe(SIMPLE_BLOB_VIEWER);

      richBtn.vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(eventHub.$emit).toHaveBeenCalledWith('switch-viewer', RICH_BLOB_VIEWER);
      });
    });

    it('emits an event when a Simple Viewer button is clicked', () => {
      factory({
        activeViewer: RICH_BLOB_VIEWER,
      });
      simpleBtn.vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(eventHub.$emit).toHaveBeenCalledWith('switch-viewer', SIMPLE_BLOB_VIEWER);
      });
    });
  });
});
