import { shallowMount } from '@vue/test-utils';
import BlobEditContent from '~/blob/components/blob_edit_content.vue';
import * as utils from '~/blob/utils';
import Editor from '~/editor/editor_lite';
import { nextTick } from 'vue';

jest.mock('~/editor/editor_lite');

describe('Blob Header Editing', () => {
  let wrapper;
  const value = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
  const fileName = 'lorem.txt';
  const fileGlobalId = 'snippet_777';

  function createComponent(props = {}) {
    wrapper = shallowMount(BlobEditContent, {
      propsData: {
        value,
        fileName,
        fileGlobalId,
        ...props,
      },
    });
  }

  beforeEach(() => {
    jest.spyOn(utils, 'initEditorLite');

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const triggerChangeContent = val => {
    jest.spyOn(Editor.prototype, 'getValue').mockReturnValue(val);
    const [cb] = Editor.prototype.onChangeContent.mock.calls[0];

    cb();

    jest.runOnlyPendingTimers();
  };

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
      expect(utils.initEditorLite).toHaveBeenCalledWith({
        el,
        blobPath: fileName,
        blobGlobalId: fileGlobalId,
        blobContent: value,
      });
    });

    it('reacts to the changes in fileName', () => {
      const newFileName = 'ipsum.txt';

      wrapper.setProps({
        fileName: newFileName,
      });

      return nextTick().then(() => {
        expect(Editor.prototype.updateModelLanguage).toHaveBeenCalledWith(newFileName);
      });
    });

    it('registers callback with editor onChangeContent', () => {
      expect(Editor.prototype.onChangeContent).toHaveBeenCalledWith(expect.any(Function));
    });

    it('emits input event when the blob content is changed', () => {
      expect(wrapper.emitted().input).toBeUndefined();

      triggerChangeContent(value);

      expect(wrapper.emitted().input).toEqual([[value]]);
    });
  });
});
