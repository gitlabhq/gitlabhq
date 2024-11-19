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
import CodeBlockBubbleMenu from '~/content_editor/components/bubble_menus/code_block_bubble_menu.vue';
import eventHubFactory from '~/helpers/event_hub_factory';
import BubbleMenu from '~/content_editor/components/bubble_menus/bubble_menu.vue';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import Diagram from '~/content_editor/extensions/diagram';
import codeBlockLanguageLoader from '~/content_editor/services/code_block_language_loader';
import { createTestEditor, emitEditorEvent } from '../../test_utils';

const createFakeEvent = () => ({ preventDefault: jest.fn(), stopPropagation: jest.fn() });

describe('content_editor/components/bubble_menus/code_block_bubble_menu', () => {
  let wrapper;
  let tiptapEditor;
  let contentEditor;
  let bubbleMenu;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({ extensions: [CodeBlockHighlight, Diagram] });
    contentEditor = { renderDiagram: jest.fn() };
    eventHub = eventHubFactory();
  };

  const buildWrapper = () => {
    wrapper = mountExtended(CodeBlockBubbleMenu, {
      provide: {
        tiptapEditor,
        contentEditor,
        eventHub,
      },
      stubs: {
        GlDropdownItem: stubComponent(GlDropdownItem),
        BubbleMenu: stubComponent(BubbleMenu),
      },
    });
  };

  const preTag = ({ language, content = 'test' } = {}) => {
    const languageAttr = language ? ` data-canonical-lang="${language}"` : '';

    return `<pre class="code highlight js-syntax-highlight"${languageAttr}>${content}</pre>`;
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

  it('renders bubble menu component', async () => {
    tiptapEditor.commands.insertContent(preTag());
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(bubbleMenu.classes()).toEqual(['gl-rounded-base', 'gl-bg-white', 'gl-shadow']);
  });

  it('selects plaintext language by default', async () => {
    tiptapEditor.commands.insertContent(preTag());
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlDropdown).props('text')).toBe('Plain text');
    expect(wrapper.findComponent(GlDropdown).attributes('contenteditable')).toBe(String(false));
  });

  it('selects appropriate language based on the code block', async () => {
    tiptapEditor.commands.insertContent(preTag({ language: 'javascript' }));
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlDropdown).props('text')).toBe('Javascript');
  });

  it('selects diagram sytnax for mermaid', async () => {
    tiptapEditor.commands.insertContent(preTag({ language: 'mermaid' }));
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlDropdown).props('text')).toBe('Diagram (mermaid)');
  });

  it("selects Custom (syntax) if the language doesn't exist in the list", async () => {
    tiptapEditor.commands.insertContent(preTag({ language: 'nomnoml' }));
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlDropdown).props('text')).toBe('Custom (nomnoml)');
  });

  describe('copy button', () => {
    it('copies the text of the code block', async () => {
      const content = 'var a = Math.PI / 2;';
      jest.spyOn(navigator.clipboard, 'writeText');

      tiptapEditor.commands.insertContent(preTag({ language: 'javascript', content }));

      await wrapper.findByTestId('copy-code-block').vm.$emit('click');

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(content);
    });
  });

  describe('delete button', () => {
    it('deletes the code block', async () => {
      tiptapEditor.commands.insertContent(preTag({ language: 'javascript' }));

      await wrapper.findByTestId('delete-code-block').vm.$emit('click');

      expect(tiptapEditor.getText()).toBe('');
    });
  });

  describe('preview button', () => {
    it('does not appear for a regular code block', () => {
      tiptapEditor.commands.insertContent('<pre data-canonical-lang="javascript">var a = 2;</pre>');

      expect(wrapper.findByTestId('preview-diagram').exists()).toBe(false);
    });

    it.each`
      diagramType  | diagramCode
      ${'mermaid'} | ${'<pre data-canonical-lang="mermaid">graph TD;\n    A-->B;</pre>'}
      ${'nomnoml'} | ${'<img data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,WzxmcmFtZT5EZWNvcmF0b3IgcGF0dGVybl0=">'}
    `('toggles preview for a $diagramType diagram', async ({ diagramType, diagramCode }) => {
      tiptapEditor.commands.insertContent(diagramCode);

      await nextTick();
      await wrapper.findByTestId('preview-diagram').vm.$emit('click');

      expect(tiptapEditor.getAttributes(Diagram.name)).toEqual({
        isDiagram: true,
        language: diagramType,
        showPreview: false,
      });

      await wrapper.findByTestId('preview-diagram').vm.$emit('click');

      expect(tiptapEditor.getAttributes(Diagram.name)).toEqual({
        isDiagram: true,
        language: diagramType,
        showPreview: true,
      });
    });
  });

  describe('when opened and search is changed', () => {
    beforeEach(async () => {
      tiptapEditor.commands.insertContent(preTag({ language: 'javascript' }));

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
        tiptapEditor.commands.insertContent(
          '<pre data-canonical-lang="javascript">var a = 2;</pre>',
        );

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

        it('hides the custom language input form and shows dropdown items', () => {
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
