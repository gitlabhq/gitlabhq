import { GlCollapsibleListbox, GlForm, GlFormInput } from '@gitlab/ui';
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
        BubbleMenu: stubComponent(BubbleMenu),
      },
    });
  };

  const preTag = ({ language, content = 'test' } = {}) => {
    const languageAttr = language ? ` data-canonical-lang="${language}"` : '';

    return `<pre class="code highlight js-syntax-highlight"${languageAttr}>${content}</pre>`;
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  beforeEach(() => {
    buildEditor();
    buildWrapper();
  });

  it('renders bubble menu component', async () => {
    tiptapEditor.commands.insertContent(preTag());
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(bubbleMenu.classes()).toEqual(['gl-rounded-base', 'gl-bg-overlap', 'gl-shadow']);
  });

  it('selects plaintext language by default', async () => {
    tiptapEditor.commands.insertContent(preTag());
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });
    await nextTick();

    expect(wrapper.findComponent(GlCollapsibleListbox).props('toggleText')).toBe('Plain text');
  });

  it('selects appropriate language based on the code block', async () => {
    tiptapEditor.commands.insertContent(preTag({ language: 'javascript' }));
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlCollapsibleListbox).props('toggleText')).toBe('Javascript');
  });

  it('selects diagram sytnax for mermaid', async () => {
    tiptapEditor.commands.insertContent(preTag({ language: 'mermaid' }));
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlCollapsibleListbox).props('toggleText')).toBe(
      'Diagram (mermaid)',
    );
  });

  it("selects Custom (syntax) if the language doesn't exist in the list", async () => {
    tiptapEditor.commands.insertContent(preTag({ language: 'nomnoml' }));
    bubbleMenu = wrapper.findComponent(BubbleMenu);

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.findComponent(GlCollapsibleListbox).props('toggleText')).toBe(
      'Custom (nomnoml)',
    );
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

      wrapper.findComponent(GlCollapsibleListbox).vm.$emit('input', 'js');

      await nextTick();
    });

    it('shows filtered dropdown items', () => {
      const items = wrapper.findComponent(GlCollapsibleListbox).props('items');
      expect(items).toEqual(
        expect.arrayContaining([
          { text: 'Javascript', value: 'javascript' },
          { text: 'Java', value: 'java' },
          { text: 'JSON', value: 'json' },
        ]),
      );
    });

    describe('when dropdown item is clicked', () => {
      beforeEach(async () => {
        jest.spyOn(codeBlockLanguageLoader, 'loadLanguage').mockResolvedValue();
        wrapper.findComponent(GlCollapsibleListbox).vm.$emit('select', 'java');
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
        expect(wrapper.findComponent(GlCollapsibleListbox).props('toggleText')).toBe('Java');
      });
    });

    describe('Create custom type', () => {
      beforeEach(async () => {
        tiptapEditor.commands.insertContent(
          '<pre data-canonical-lang="javascript">var a = 2;</pre>',
        );
        await wrapper.findByTestId('create-custom-type').trigger('click');
      });

      it('shows custom language input form and hides dropdown items', () => {
        expect(wrapper.findComponent(GlFormInput).exists()).toBe(true);
        expect(wrapper.findComponent(GlForm).exists()).toBe(true);
      });

      describe('on bubble menu hide', () => {
        it('hides the form', async () => {
          wrapper.findComponent(GlFormInput).setValue('foobar');
          await wrapper.findComponent(BubbleMenu).vm.$emit('hidden');

          expect(findListbox().exists()).toBe(true);
          expect(wrapper.findComponent(GlForm).exists()).toBe(false);
          expect(findListbox().props('items').length).toBeGreaterThan(0);
        });
      });

      describe('on clicking apply', () => {
        beforeEach(async () => {
          await wrapper.findComponent(GlFormInput).setValue('foobar');
          await wrapper.findComponent(GlForm).trigger('submit');
          await emitEditorEvent({ event: 'transaction', tiptapEditor });
        });

        it('updates dropdown value to the custom language type', () => {
          expect(wrapper.findComponent(GlCollapsibleListbox).props('toggleText')).toBe(
            'Custom (foobar)',
          );
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
