import { GlButton } from '@gitlab/ui';
import { Extension } from '@tiptap/core';
import { shallowMount } from '@vue/test-utils';
import ToolbarButton from '~/content_editor/components/toolbar_button.vue';
import { createContentEditor } from '~/content_editor/services/create_content_editor';

describe('content_editor/components/toolbar_button', () => {
  let wrapper;
  let tiptapEditor;
  let toggleFooSpy;
  const CONTENT_TYPE = 'bold';
  const ICON_NAME = 'bold';
  const LABEL = 'Bold';

  const buildEditor = () => {
    toggleFooSpy = jest.fn();
    tiptapEditor = createContentEditor({
      extensions: [
        {
          tiptapExtension: Extension.create({
            addCommands() {
              return {
                toggleFoo: () => toggleFooSpy,
              };
            },
          }),
        },
      ],
      renderMarkdown: () => true,
    }).tiptapEditor;

    jest.spyOn(tiptapEditor, 'isActive');
  };

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(ToolbarButton, {
      stubs: {
        GlButton,
      },
      propsData: {
        tiptapEditor,
        contentType: CONTENT_TYPE,
        iconName: ICON_NAME,
        label: LABEL,
        ...propsData,
      },
    });
  };
  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    buildEditor();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays tertiary, small button with a provided label and icon', () => {
    buildWrapper();

    expect(findButton().html()).toMatchSnapshot();
  });

  it.each`
    editorState                             | outcomeDescription         | outcome
    ${{ isActive: true, isFocused: true }}  | ${'button is active'}      | ${true}
    ${{ isActive: false, isFocused: true }} | ${'button is not active'}  | ${false}
    ${{ isActive: true, isFocused: false }} | ${'button is not active '} | ${false}
  `('$outcomeDescription when when editor state is $editorState', ({ editorState, outcome }) => {
    tiptapEditor.isActive.mockReturnValueOnce(editorState.isActive);
    tiptapEditor.isFocused = editorState.isFocused;
    buildWrapper();

    expect(findButton().classes().includes('active')).toBe(outcome);
    expect(tiptapEditor.isActive).toHaveBeenCalledWith(CONTENT_TYPE);
  });

  describe('when button is clicked', () => {
    it('executes the content type command when executeCommand = true', async () => {
      buildWrapper({ editorCommand: 'toggleFoo' });

      await findButton().trigger('click');

      expect(toggleFooSpy).toHaveBeenCalled();
      expect(wrapper.emitted().execute).toHaveLength(1);
    });

    it('does not executes the content type command when executeCommand = false', async () => {
      buildWrapper();

      await findButton().trigger('click');

      expect(toggleFooSpy).not.toHaveBeenCalled();
      expect(wrapper.emitted().execute).toHaveLength(1);
    });
  });
});
