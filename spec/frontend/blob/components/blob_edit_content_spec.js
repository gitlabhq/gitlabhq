import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import BlobEditContent from '~/blob/components/blob_edit_content.vue';
import * as utils from '~/blob/utils';

jest.mock('~/editor/source_editor');

describe('Blob Header Editing', () => {
  let wrapper;
  const onDidChangeModelContent = jest.fn();
  const updateModelLanguage = jest.fn();
  const getValue = jest.fn();
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
    jest.spyOn(utils, 'initSourceEditor').mockImplementation(() => ({
      onDidChangeModelContent,
      updateModelLanguage,
      getValue,
      dispose: jest.fn(),
    }));

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const triggerChangeContent = (val) => {
    getValue.mockReturnValue(val);
    const [cb] = onDidChangeModelContent.mock.calls[0];

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
      expect(wrapper.find('#editor').exists()).toBe(true);
    });

    it('initialises Source Editor', () => {
      const el = wrapper.find({ ref: 'editor' }).element;
      expect(utils.initSourceEditor).toHaveBeenCalledWith({
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
        expect(updateModelLanguage).toHaveBeenCalledWith(newFileName);
      });
    });

    it('registers callback with editor onChangeContent', () => {
      expect(onDidChangeModelContent).toHaveBeenCalledWith(expect.any(Function));
    });

    it('emits input event when the blob content is changed', () => {
      expect(wrapper.emitted().input).toBeUndefined();

      triggerChangeContent(value);

      expect(wrapper.emitted().input).toEqual([[value]]);
    });
  });
});
