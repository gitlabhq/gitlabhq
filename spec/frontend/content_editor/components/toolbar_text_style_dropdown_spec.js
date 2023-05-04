import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import ToolbarTextStyleDropdown from '~/content_editor/components/toolbar_text_style_dropdown.vue';
import { TEXT_STYLE_DROPDOWN_ITEMS } from '~/content_editor/constants';
import Heading from '~/content_editor/extensions/heading';
import eventHubFactory from '~/helpers/event_hub_factory';
import { createTestEditor, mockChainedCommands, emitEditorEvent } from '../test_utils';

describe('content_editor/components/toolbar_text_style_dropdown', () => {
  let wrapper;
  let tiptapEditor;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({
      extensions: [Heading],
    });

    jest.spyOn(tiptapEditor, 'isActive');
  };

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMountExtended(ToolbarTextStyleDropdown, {
      stubs: {
        EditorStateObserver,
      },
      provide: {
        tiptapEditor,
        eventHub: eventHubFactory(),
      },
      propsData: {
        ...propsData,
      },
    });
  };
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  beforeEach(() => {
    buildEditor();
  });

  it('renders all text styles as dropdown items', () => {
    buildWrapper();

    TEXT_STYLE_DROPDOWN_ITEMS.forEach((textStyle, index) => {
      expect(findListbox().props('items').at(index).text).toContain(textStyle.label);
    });
    expect(findListbox().props('items').length).toBe(TEXT_STYLE_DROPDOWN_ITEMS.length);
  });

  describe('when there is an active item', () => {
    let activeTextStyle;

    beforeEach(async () => {
      [, activeTextStyle] = TEXT_STYLE_DROPDOWN_ITEMS;

      tiptapEditor.isActive.mockImplementation(
        (contentType, params) =>
          activeTextStyle.contentType === contentType && activeTextStyle.commandParams === params,
      );

      buildWrapper();
      await emitEditorEvent({ event: 'transaction', tiptapEditor });
    });

    it('displays the active text style label as the dropdown toggle text', () => {
      expect(findListbox().props('toggleText')).toBe(activeTextStyle.label);
    });

    it('sets dropdown as enabled', () => {
      expect(findListbox().props('disabled')).toBe(false);
    });
  });

  describe('when there isn’t an active item', () => {
    beforeEach(async () => {
      tiptapEditor.isActive.mockReturnValue(false);
      buildWrapper();
      await emitEditorEvent({ event: 'transaction', tiptapEditor });
    });

    it('sets dropdown as disabled', () => {
      expect(findListbox().props('disabled')).toBe(true);
    });

    it('sets dropdown toggle text to Text style', () => {
      expect(findListbox().props('toggleText')).toBe('Text style');
    });
  });

  describe('when a text style is selected', () => {
    it('executes the tiptap command related to that text style', () => {
      buildWrapper();

      TEXT_STYLE_DROPDOWN_ITEMS.forEach((textStyle, index) => {
        const { editorCommand, commandParams } = textStyle;
        const commands = mockChainedCommands(tiptapEditor, [editorCommand, 'focus', 'run']);

        findListbox().vm.$emit('select', TEXT_STYLE_DROPDOWN_ITEMS[index].label);
        expect(commands[editorCommand]).toHaveBeenCalledWith(commandParams || {});
        expect(commands.focus).toHaveBeenCalled();
        expect(commands.run).toHaveBeenCalled();
      });
    });

    it('emits execute event with contentType and value params that indicates the heading level', () => {
      TEXT_STYLE_DROPDOWN_ITEMS.forEach((textStyle, index) => {
        buildWrapper();
        const { contentType, commandParams } = textStyle;

        findListbox().vm.$emit('select', TEXT_STYLE_DROPDOWN_ITEMS[index].label);
        expect(wrapper.emitted('execute')).toEqual([
          [
            {
              contentType,
              value: commandParams?.level,
            },
          ],
        ]);
      });
    });
  });
});
