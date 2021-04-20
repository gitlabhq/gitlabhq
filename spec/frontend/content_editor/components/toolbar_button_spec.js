import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ToolbarButton from '~/content_editor/components/toolbar_button.vue';

describe('content_editor/components/toolbar_button', () => {
  let wrapper;
  let editor;
  const CONTENT_TYPE = 'bold';
  const ICON_NAME = 'bold';
  const LABEL = 'Bold';

  const buildEditor = () => {
    editor = {
      isActive: {
        [CONTENT_TYPE]: jest.fn(),
      },
      commands: {
        [CONTENT_TYPE]: jest.fn(),
      },
    };
  };

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(ToolbarButton, {
      stubs: {
        GlButton,
      },
      propsData: {
        editor,
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
    editorState                           | outcomeDescription         | outcome
    ${{ isActive: true, focused: true }}  | ${'button is active'}      | ${true}
    ${{ isActive: false, focused: true }} | ${'button is not active'}  | ${false}
    ${{ isActive: true, focused: false }} | ${'button is not active '} | ${false}
  `('$outcomeDescription when when editor state is $editorState', ({ editorState, outcome }) => {
    editor.isActive[CONTENT_TYPE].mockReturnValueOnce(editorState.isActive);
    editor.focused = editorState.focused;
    buildWrapper();

    expect(findButton().classes().includes('active')).toBe(outcome);
  });

  describe('when button is clicked', () => {
    it('executes the content type command when executeCommand = true', async () => {
      buildWrapper({ executeCommand: true });

      await findButton().trigger('click');

      expect(editor.commands[CONTENT_TYPE]).toHaveBeenCalled();
      expect(wrapper.emitted().click).toHaveLength(1);
    });

    it('does not executes the content type command when executeCommand = false', async () => {
      buildWrapper({ executeCommand: false });

      await findButton().trigger('click');

      expect(editor.commands[CONTENT_TYPE]).not.toHaveBeenCalled();
      expect(wrapper.emitted().click).toHaveLength(1);
    });
  });
});
