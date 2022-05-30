import { BubbleMenu } from '@tiptap/vue-2';
import {
  GlDropdown,
  GlDropdownForm,
  GlDropdownItem,
  GlSearchBoxByType,
  GlFormInput,
} from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import CodeBlockBubbleMenu from '~/content_editor/components/bubble_menus/code_block.vue';
import eventHubFactory from '~/helpers/event_hub_factory';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import codeBlockLanguageLoader from '~/content_editor/services/code_block_language_loader';
import { createTestEditor, emitEditorEvent } from '../../test_utils';

const createFakeEvent = () => ({ preventDefault: jest.fn(), stopPropagation: jest.fn() });

describe('content_editor/components/bubble_menus/code_block', () => {
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
      stubs: {
        GlDropdownItem: stubComponent(GlDropdownItem),
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

  beforeEach(async () => {
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
    expect(bubbleMenu.classes()).toEqual(['gl-shadow', 'gl-rounded-base', 'gl-bg-white']);
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

  describe('copy button', () => {
    it('copies the text of the code block', async () => {
      jest.spyOn(navigator.clipboard, 'writeText');

      tiptapEditor.commands.insertContent('<pre lang="javascript">var a = Math.PI / 2;</pre>');

      await wrapper.findByTestId('copy-code-block').vm.$emit('click');

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith('var a = Math.PI / 2;');
    });
  });

  describe('delete button', () => {
    it('deletes the code block', async () => {
      tiptapEditor.commands.insertContent('<pre lang="javascript">var a = 2;</pre>');

      await wrapper.findByTestId('delete-code-block').vm.$emit('click');

      expect(tiptapEditor.getText()).toBe('');
    });
  });

  describe('when opened and search is changed', () => {
    beforeEach(async () => {
      tiptapEditor.commands.insertContent('<pre lang="javascript">var a = 2;</pre>');

      wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', 'js');

      await nextTick();
    });

    it('shows dropdown items', () => {
      expect(findDropdownItemsData()).toEqual(
        expect.arrayContaining([
          { text: 'Javascript', visible: true, checked: true },
          { text: 'Java', visible: true, checked: false },
          { text: 'Javascript', visible: false, checked: false },
          { text: 'JSON', visible: true, checked: false },
        ]),
      );
    });

    describe('when dropdown item is clicked', () => {
      beforeEach(async () => {
        jest.spyOn(codeBlockLanguageLoader, 'loadLanguage').mockResolvedValue();

        findDropdownItems().at(1).vm.$emit('click');

        await nextTick();
      });

      it('loads language', () => {
        expect(codeBlockLanguageLoader.loadLanguage).toHaveBeenCalledWith('java');
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

    describe('Create custom type', () => {
      beforeEach(async () => {
        tiptapEditor.commands.insertContent('<pre lang="javascript">var a = 2;</pre>');

        await wrapper.findComponent(GlDropdown).vm.show();
        await wrapper.findByTestId('create-custom-type').trigger('click');
      });

      it('shows custom language input form and hides dropdown items', () => {
        expect(wrapper.findComponent(GlDropdownItem).exists()).toBe(false);
        expect(wrapper.findComponent(GlSearchBoxByType).exists()).toBe(false);
        expect(wrapper.findComponent(GlDropdownForm).exists()).toBe(true);
      });

      describe('on clicking back', () => {
        it('hides the custom language input form and shows dropdown items', async () => {
          await wrapper.findByRole('button', { name: 'Go back' }).trigger('click');

          expect(wrapper.findComponent(GlDropdownItem).exists()).toBe(true);
          expect(wrapper.findComponent(GlSearchBoxByType).exists()).toBe(true);
          expect(wrapper.findComponent(GlDropdownForm).exists()).toBe(false);
        });
      });

      describe('on clicking cancel', () => {
        it('hides the custom language input form and shows dropdown items', async () => {
          await wrapper.findByRole('button', { name: 'Cancel' }).trigger('click');

          expect(wrapper.findComponent(GlDropdownItem).exists()).toBe(true);
          expect(wrapper.findComponent(GlSearchBoxByType).exists()).toBe(true);
          expect(wrapper.findComponent(GlDropdownForm).exists()).toBe(false);
        });
      });

      describe('on dropdown hide', () => {
        it('hides the form', async () => {
          wrapper.findComponent(GlFormInput).setValue('foobar');
          await wrapper.findComponent(GlDropdown).vm.$emit('hide');

          expect(wrapper.findComponent(GlDropdownItem).exists()).toBe(true);
          expect(wrapper.findComponent(GlSearchBoxByType).exists()).toBe(true);
          expect(wrapper.findComponent(GlDropdownForm).exists()).toBe(false);
        });
      });

      describe('on clicking apply', () => {
        beforeEach(async () => {
          wrapper.findComponent(GlFormInput).setValue('foobar');
          await wrapper.findComponent(GlDropdownForm).vm.$emit('submit', createFakeEvent());

          await emitEditorEvent({ event: 'transaction', tiptapEditor });
        });

        it('hides the custom language input form and shows dropdown items', async () => {
          expect(wrapper.findComponent(GlDropdownItem).exists()).toBe(true);
          expect(wrapper.findComponent(GlSearchBoxByType).exists()).toBe(true);
          expect(wrapper.findComponent(GlDropdownForm).exists()).toBe(false);
        });

        it('updates dropdown value to the custom language type', () => {
          expect(wrapper.findComponent(GlDropdown).props('text')).toBe('Custom (foobar)');
        });

        it('updates tiptap editor to the custom language type', () => {
          expect(tiptapEditor.getAttributes(CodeBlockHighlight.name)).toEqual(
            expect.objectContaining({
              language: 'foobar',
            }),
          );
        });
      });
    });
  });
});
