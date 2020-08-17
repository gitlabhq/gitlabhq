import { mount } from '@vue/test-utils';
import { GlButtonGroup, GlButton } from '@gitlab/ui';
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

  afterEach(() => {
    wrapper.destroy();
  });

  describe('intiialization', () => {
    it('is initialized with simple viewer as active', () => {
      createComponent();
      expect(wrapper.vm.value).toBe(SIMPLE_BLOB_VIEWER);
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

    function factory(propsData = {}) {
      createComponent(propsData);
      buttons = wrapper.findAll(GlButton);
      simpleBtn = buttons.at(0);
      richBtn = buttons.at(1);

      jest.spyOn(wrapper.vm, '$emit');
    }

    it('does not switch the viewer if the selected one is already active', () => {
      factory();
      expect(wrapper.vm.value).toBe(SIMPLE_BLOB_VIEWER);
      simpleBtn.vm.$emit('click');
      expect(wrapper.vm.value).toBe(SIMPLE_BLOB_VIEWER);
      expect(wrapper.vm.$emit).not.toHaveBeenCalled();
    });

    it('emits an event when a Rich Viewer button is clicked', () => {
      factory();
      expect(wrapper.vm.value).toBe(SIMPLE_BLOB_VIEWER);

      richBtn.vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.$emit).toHaveBeenCalledWith('input', RICH_BLOB_VIEWER);
      });
    });

    it('emits an event when a Simple Viewer button is clicked', () => {
      factory({
        value: RICH_BLOB_VIEWER,
      });
      simpleBtn.vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.$emit).toHaveBeenCalledWith('input', SIMPLE_BLOB_VIEWER);
      });
    });
  });
});
