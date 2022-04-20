import { BubbleMenu } from '@tiptap/vue-2';
import { GlButton, GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CodeBlockBubbleMenu from '~/content_editor/components/code_block_bubble_menu.vue';
import eventHubFactory from '~/helpers/event_hub_factory';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import codeBlockLanguageLoader from '~/content_editor/services/code_block_language_loader';
import { createTestEditor, emitEditorEvent } from '../test_utils';

describe('content_editor/components/code_block_bubble_menu', () => {
  let wrapper;
  let tiptapEditor;
  let bubbleMenu;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({ extensions: [CodeBlockHighlight] });
    eventHub = eventHubFactory();
  };

  const buildWrapper = () => {
    wrapper = mountExtended(CodeBlockBubbleMenu, {
      provide: {
        tiptapEditor,
        eventHub,
      },
    });
  };

  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemsData = () =>
    findDropdownItems().wrappers.map((x) => ({
      text: x.text(),
      visible: x.isVisible(),
      checked: x.props('isChecked'),
    }));

  beforeEach(() => {
    buildEditor();
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders bubble menu component', async () => {
    tiptapEditor.commands.insertContent('<pre>test</pre>');
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(bubbleMenu.props('editor')).toBe(tiptapEditor);
    expect(bubbleMenu.classes()).toEqual(['gl-shadow', 'gl-rounded-base']);
  });

  it('selects plaintext language by default', async () => {
    tiptapEditor.commands.insertContent('<pre>test</pre>');
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlDropdown).props('text')).toBe('Plain text');
  });

  it('selects appropriate language based on the code block', async () => {
    tiptapEditor.commands.insertContent('<pre lang="javascript">var a = 2;</pre>');
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlDropdown).props('text')).toBe('Javascript');
  });

  it("selects Custom (syntax) if the language doesn't exist in the list", async () => {
    tiptapEditor.commands.insertContent('<pre lang="nomnoml">test</pre>');
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlDropdown).props('text')).toBe('Custom (nomnoml)');
  });

  it('delete button deletes the code block', async () => {
    tiptapEditor.commands.insertContent('<pre lang="javascript">var a = 2;</pre>');

    await wrapper.findComponent(GlButton).vm.$emit('click');

    expect(tiptapEditor.getText()).toBe('');
  });

  describe('when opened and search is changed', () => {
    beforeEach(async () => {
      tiptapEditor.commands.insertContent('<pre lang="javascript">var a = 2;</pre>');

      wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', 'js');

      await Vue.nextTick();
    });

    it('shows dropdown items', () => {
      expect(findDropdownItemsData()).toEqual([
        { text: 'Javascript', visible: true, checked: true },
        { text: 'Java', visible: true, checked: false },
        { text: 'Javascript', visible: false, checked: false },
        { text: 'JSON', visible: true, checked: false },
      ]);
    });

    describe('when dropdown item is clicked', () => {
      beforeEach(async () => {
        jest.spyOn(codeBlockLanguageLoader, 'loadLanguages').mockResolvedValue();

        findDropdownItems().at(1).vm.$emit('click');

        await Vue.nextTick();
      });

      it('loads language', () => {
        expect(codeBlockLanguageLoader.loadLanguages).toHaveBeenCalledWith(['java']);
      });

      it('sets code block', () => {
        expect(tiptapEditor.getJSON()).toMatchObject({
          content: [
            {
              type: 'codeBlock',
              attrs: {
                language: 'java',
              },
            },
          ],
        });
      });

      it('updates selected dropdown', () => {
        expect(wrapper.findComponent(GlDropdown).props('text')).toBe('Java');
      });
    });
  });
});
