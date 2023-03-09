import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { EDITOR_READY_EVENT } from '~/editor/constants';
import Editor from '~/editor/source_editor';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import * as helpers from 'jest/editor/helpers';

jest.mock('~/editor/source_editor');

describe('Source Editor component', () => {
  let wrapper;
  let mockInstance;

  const value = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
  const fileName = 'lorem.txt';
  const fileGlobalId = 'snippet_777';
  const useSpy = jest.fn();
  const createInstanceMock = jest.fn().mockImplementation(() => {
    mockInstance = {
      onDidChangeModelContent: jest.fn(),
      updateModelLanguage: jest.fn(),
      getValue: jest.fn(),
      setValue: jest.fn(),
      dispose: jest.fn(),
      use: useSpy,
    };
    return mockInstance;
  });

  Editor.mockImplementation(() => {
    return {
      createInstance: createInstanceMock,
    };
  });
  function createComponent(props = {}) {
    wrapper = shallowMount(SourceEditor, {
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

  const triggerChangeContent = (val) => {
    mockInstance.getValue.mockReturnValue(val);
    const [cb] = mockInstance.onDidChangeModelContent.mock.calls[0];

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
      expect(wrapper.find('[id^="source-editor-"]').exists()).toBe(true);
    });

    it('initialises Source Editor instance', () => {
      const el = wrapper.findComponent({ ref: 'editor' }).element;
      expect(createInstanceMock).toHaveBeenCalledWith({
        el,
        blobPath: fileName,
        blobGlobalId: fileGlobalId,
        blobContent: value,
      });
    });

    it.each`
      description                           | extensions                                                                                                          | toBeCalled
      ${'no extension when `undefined` is'} | ${undefined}                                                                                                        | ${false}
      ${'no extension when {} is'}          | ${{}}                                                                                                               | ${false}
      ${'no extension when [] is'}          | ${[]}                                                                                                               | ${false}
      ${'single extension'}                 | ${{ definition: helpers.SEClassExtension }}                                                                         | ${true}
      ${'single extension with options'}    | ${{ definition: helpers.SEWithSetupExt, setupOptions: { foo: 'bar' } }}                                             | ${true}
      ${'multiple extensions'}              | ${[{ definition: helpers.SEClassExtension }, { definition: helpers.SEWithSetupExt }]}                               | ${true}
      ${'multiple extensions with options'} | ${[{ definition: helpers.SEClassExtension }, { definition: helpers.SEWithSetupExt, setupOptions: { foo: 'bar' } }]} | ${true}
    `('installs $description passed as a prop', ({ extensions, toBeCalled }) => {
      createComponent({ extensions });
      if (toBeCalled) {
        expect(useSpy).toHaveBeenCalledWith(extensions);
      } else {
        expect(useSpy).not.toHaveBeenCalled();
      }
    });

    it('reacts to the changes in fileName', () => {
      const newFileName = 'ipsum.txt';

      wrapper.setProps({
        fileName: newFileName,
      });

      return nextTick().then(() => {
        expect(mockInstance.updateModelLanguage).toHaveBeenCalledWith(newFileName);
      });
    });

    it('registers callback with editor onChangeContent', () => {
      expect(mockInstance.onDidChangeModelContent).toHaveBeenCalledWith(expect.any(Function));
    });

    it('emits input event when the blob content is changed', () => {
      expect(wrapper.emitted().input).toBeUndefined();

      triggerChangeContent(value);

      expect(wrapper.emitted().input).toEqual([[value]]);
    });

    it('emits EDITOR_READY_EVENT event when the Source Editor is ready', async () => {
      const el = wrapper.findComponent({ ref: 'editor' }).element;
      expect(wrapper.emitted()[EDITOR_READY_EVENT]).toBeUndefined();

      await el.dispatchEvent(new Event(EDITOR_READY_EVENT));

      expect(wrapper.emitted()[EDITOR_READY_EVENT]).toBeDefined();
    });

    it('component API `getEditor()` returns the editor instance', () => {
      expect(wrapper.vm.getEditor()).toBe(mockInstance);
    });

    describe('reaction to the value update', () => {
      it('reacts to the changes in the passed value', async () => {
        const newValue = 'New Value';

        wrapper.setProps({
          value: newValue,
        });

        await nextTick();
        expect(mockInstance.setValue).toHaveBeenCalledWith(newValue);
      });

      it("does not update value if the passed one is exactly the same as the editor's content", async () => {
        const newValue = `${value}`; // to make sure we're creating a new String with the same content and not just a reference

        wrapper.setProps({
          value: newValue,
        });

        await nextTick();
        expect(mockInstance.setValue).not.toHaveBeenCalled();
      });
    });
  });
});
