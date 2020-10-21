import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import Editor from '~/editor/editor_lite';

jest.mock('~/editor/editor_lite');

describe('Editor Lite component', () => {
  let wrapper;
  const onDidChangeModelContent = jest.fn();
  const updateModelLanguage = jest.fn();
  const getValue = jest.fn();
  const setValue = jest.fn();
  const value = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
  const fileName = 'lorem.txt';
  const fileGlobalId = 'snippet_777';
  const createInstanceMock = jest.fn().mockImplementation(() => ({
    onDidChangeModelContent,
    updateModelLanguage,
    getValue,
    setValue,
    dispose: jest.fn(),
  }));
  Editor.mockImplementation(() => {
    return {
      createInstance: createInstanceMock,
    };
  });
  function createComponent(props = {}) {
    wrapper = shallowMount(EditorLite, {
      propsData: {
        value,
        fileName,
        fileGlobalId,
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

  const triggerChangeContent = val => {
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
      expect(wrapper.find('[id^="editor-lite-"]').exists()).toBe(true);
    });

    it('initialises Editor Lite instance', () => {
      const el = wrapper.find({ ref: 'editor' }).element;
      expect(createInstanceMock).toHaveBeenCalledWith({
        el,
        blobPath: fileName,
        blobGlobalId: fileGlobalId,
        blobContent: value,
        extensions: null,
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

    it('emits editor-ready event when the Editor Lite is ready', async () => {
      const el = wrapper.find({ ref: 'editor' }).element;
      expect(wrapper.emitted()['editor-ready']).toBeUndefined();

      await el.dispatchEvent(new Event('editor-ready'));

      expect(wrapper.emitted()['editor-ready']).toBeDefined();
    });

    describe('reaction to the value update', () => {
      it('reacts to the changes in the passed value', async () => {
        const newValue = 'New Value';

        wrapper.setProps({
          value: newValue,
        });

        await nextTick();
        expect(setValue).toHaveBeenCalledWith(newValue);
      });

      it("does not update value if the passed one is exactly the same as the editor's content", async () => {
        const newValue = `${value}`; // to make sure we're creating a new String with the same content and not just a reference

        wrapper.setProps({
          value: newValue,
        });

        await nextTick();
        expect(setValue).not.toHaveBeenCalled();
      });
    });
  });
});
