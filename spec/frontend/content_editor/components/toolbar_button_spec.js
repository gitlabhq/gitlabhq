import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import ToolbarButton from '~/content_editor/components/toolbar_button.vue';
import eventHubFactory from '~/helpers/event_hub_factory';
import { createTestEditor, mockChainedCommands, emitEditorEvent } from '../test_utils';

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
        EditorStateObserver,
      },
      provide: {
        tiptapEditor,
        eventHub: eventHubFactory(),
      },
      propsData: {
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

  it('displays tertiary, medium button with a provided label and icon', () => {
    buildWrapper();

    expect(findButton().html()).toMatchSnapshot();
  });

  it('allows customizing the variant, category, size of the button', () => {
    const variant = 'danger';
    const category = 'secondary';
    const size = 'medium';

    buildWrapper({
      variant,
      category,
      size,
    });

    expect(findButton().props()).toMatchObject({
      variant,
      category,
      size,
    });
  });

  it.each`
    editorState                             | outcomeDescription         | outcome
    ${{ isActive: true, isFocused: true }}  | ${'button is active'}      | ${true}
    ${{ isActive: false, isFocused: true }} | ${'button is not active'}  | ${false}
    ${{ isActive: true, isFocused: false }} | ${'button is not active '} | ${false}
  `(
    '$outcomeDescription when when editor state is $editorState',
    async ({ editorState, outcome }) => {
      tiptapEditor.isActive.mockReturnValueOnce(editorState.isActive);
      tiptapEditor.isFocused = editorState.isFocused;

      buildWrapper();

      await emitEditorEvent({ event: 'transaction', tiptapEditor });

      expect(findButton().classes().includes('!gl-bg-gray-100')).toBe(outcome);
      expect(tiptapEditor.isActive).toHaveBeenCalledWith(CONTENT_TYPE);
    },
  );

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
