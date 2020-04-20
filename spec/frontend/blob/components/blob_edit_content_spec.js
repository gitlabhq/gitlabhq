import { shallowMount } from '@vue/test-utils';
import BlobEditContent from '~/blob/components/blob_edit_content.vue';
import { initEditorLite } from '~/blob/utils';
import { nextTick } from 'vue';

jest.mock('~/blob/utils', () => ({
  initEditorLite: jest.fn(),
}));

describe('Blob Header Editing', () => {
  let wrapper;
  const value = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
  const fileName = 'lorem.txt';

  function createComponent(props = {}) {
    wrapper = shallowMount(BlobEditContent, {
      propsData: {
        value,
        fileName,
        ...props,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders content', () => {
      expect(wrapper.text()).toContain(value);
    });
  });

  describe('functionality', () => {
    it('does not fail without content', () => {
      const spy = jest.spyOn(global.console, 'error');
      createComponent({ value: undefined });

      expect(spy).not.toHaveBeenCalled();
      expect(wrapper.contains('#editor')).toBe(true);
    });

    it('initialises Editor Lite', () => {
      const el = wrapper.find({ ref: 'editor' }).element;
      expect(initEditorLite).toHaveBeenCalledWith({
        el,
        blobPath: fileName,
        blobContent: value,
      });
    });

    it('reacts to the changes in fileName', () => {
      wrapper.vm.editor = {
        updateModelLanguage: jest.fn(),
      };

      const newFileName = 'ipsum.txt';

      wrapper.setProps({
        fileName: newFileName,
      });

      return nextTick().then(() => {
        expect(wrapper.vm.editor.updateModelLanguage).toHaveBeenCalledWith(newFileName);
      });
    });

    it('emits input event when the blob content is changed', () => {
      const editorEl = wrapper.find({ ref: 'editor' });
      wrapper.vm.editor = {
        getValue: jest.fn().mockReturnValue(value),
      };

      editorEl.trigger('keyup');

      return nextTick().then(() => {
        expect(wrapper.emitted().input[0]).toEqual([value]);
      });
    });
  });
});
