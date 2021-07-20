import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ToolbarButton from '~/content_editor/components/toolbar_button.vue';
import { createTestEditor, mockChainedCommands } from '../test_utils';

describe('content_editor/components/toolbar_button', () => {
  let wrapper;
  let tiptapEditor;
  const CONTENT_TYPE = 'bold';
  const ICON_NAME = 'bold';
  const LABEL = 'Bold';

  const buildEditor = () => {
    tiptapEditor = createTestEditor();

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
      const editorCommand = 'toggleFoo';
      const mockCommands = mockChainedCommands(tiptapEditor, [editorCommand, 'focus', 'run']);

      buildWrapper({ editorCommand });

      await findButton().trigger('click');

      expect(mockCommands[editorCommand]).toHaveBeenCalled();
      expect(mockCommands.focus).toHaveBeenCalled();
      expect(mockCommands.run).toHaveBeenCalled();
      expect(wrapper.emitted().execute).toHaveLength(1);
    });

    it('does not executes the content type command when executeCommand = false', async () => {
      const editorCommand = 'toggleFoo';
      const mockCommands = mockChainedCommands(tiptapEditor, [editorCommand, 'run']);

      buildWrapper();

      await findButton().trigger('click');

      expect(mockCommands[editorCommand]).not.toHaveBeenCalled();
      expect(wrapper.emitted().execute).toHaveLength(1);
    });
  });
});
