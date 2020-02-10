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

describe('Blob Header Viewer Switcher', () => {
  let wrapper;

  function createComponent(props = {}) {
    wrapper = mount(BlobHeaderViewerSwitcher, {
      propsData: {
        blob: Object.assign({}, Blob, props),
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('intiialization', () => {
    it('is initialized with rich viewer as preselected when richViewer exists', () => {
      createComponent();
      expect(wrapper.vm.viewer).toBe(RICH_BLOB_VIEWER);
    });

    it('is initialized with simple viewer as preselected when richViewer does not exists', () => {
      createComponent({ richViewer: null });
      expect(wrapper.vm.viewer).toBe(SIMPLE_BLOB_VIEWER);
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

    beforeEach(() => {
      createComponent();
      buttons = wrapper.findAll(GlButton);
      simpleBtn = buttons.at(0);
      richBtn = buttons.at(1);
    });

    it('does not switch the viewer if the selected one is already active', () => {
      jest.spyOn(wrapper.vm, '$emit');

      expect(wrapper.vm.viewer).toBe(RICH_BLOB_VIEWER);
      richBtn.vm.$emit('click');
      expect(wrapper.vm.viewer).toBe(RICH_BLOB_VIEWER);
      expect(wrapper.vm.$emit).not.toHaveBeenCalled();
    });

    it('emits an event when a Simple Viewer button is clicked', () => {
      jest.spyOn(wrapper.vm, '$emit');

      simpleBtn.vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.viewer).toBe(SIMPLE_BLOB_VIEWER);
        expect(wrapper.vm.$emit).toHaveBeenCalledWith('switch-viewer', SIMPLE_BLOB_VIEWER);
      });
    });

    it('emits an event when a Rich Viewer button is clicked', () => {
      jest.spyOn(wrapper.vm, '$emit');

      wrapper.setData({ viewer: SIMPLE_BLOB_VIEWER });

      return wrapper.vm
        .$nextTick()
        .then(() => {
          richBtn.vm.$emit('click');
        })
        .then(() => {
          expect(wrapper.vm.viewer).toBe(RICH_BLOB_VIEWER);
          expect(wrapper.vm.$emit).toHaveBeenCalledWith('switch-viewer', RICH_BLOB_VIEWER);
        });
    });
  });
});
