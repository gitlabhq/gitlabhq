import { nextTick } from 'vue';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import eventHubFactory from '~/helpers/event_hub_factory';
import SandboxedMermaid from '~/behaviors/components/sandboxed_mermaid.vue';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import Diagram from '~/content_editor/extensions/diagram';
import CodeBlockWrapper from '~/content_editor/components/wrappers/code_block.vue';
import codeBlockLanguageLoader from '~/content_editor/services/code_block_language_loader';
import { emitEditorEvent, createTestEditor } from '../../test_utils';

jest.mock('~/content_editor/services/code_block_language_loader');

describe('content/components/wrappers/code_block', () => {
  const language = 'yaml';
  let wrapper;
  let updateAttributesFn;
  let tiptapEditor;
  let contentEditor;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({ extensions: [CodeBlockHighlight, Diagram] });
    contentEditor = { renderDiagram: jest.fn().mockResolvedValue('url/to/some/diagram') };
    eventHub = eventHubFactory();
  };

  const createWrapper = (nodeAttrs = { language }) => {
    updateAttributesFn = jest.fn();

    wrapper = mountExtended(CodeBlockWrapper, {
      propsData: {
        editor: tiptapEditor,
        node: {
          attrs: nodeAttrs,
        },
        updateAttributes: updateAttributesFn,
      },
      stubs: {
        NodeViewContent: stubComponent(NodeViewContent),
        NodeViewWrapper: stubComponent(NodeViewWrapper),
      },
      provide: {
        contentEditor,
        tiptapEditor,
        eventHub,
      },
    });
  };

  beforeEach(() => {
    buildEditor();

    codeBlockLanguageLoader.findOrCreateLanguageBySyntax.mockReturnValue({ syntax: language });
  });

  it('renders a node-view-wrapper as a pre element', () => {
    createWrapper();

    expect(wrapper.findComponent(NodeViewWrapper).props().as).toBe('pre');
    expect(wrapper.findComponent(NodeViewWrapper).classes()).toContain('gl-relative');
  });

  it('adds content-editor-code-block class to the pre element', () => {
    createWrapper();
    expect(wrapper.findComponent(NodeViewWrapper).classes()).toContain('content-editor-code-block');
  });

  it('renders a node-view-content as a code element', () => {
    createWrapper();

    expect(wrapper.findComponent(NodeViewContent).props().as).toBe('code');
  });

  it('renders label indicating that code block is frontmatter', () => {
    createWrapper({ isFrontmatter: true, language });

    const label = wrapper.find('[data-testid="frontmatter-label"]');

    expect(label.text()).toEqual('frontmatter:yaml');
    expect(label.classes()).toEqual(['gl-absolute', 'gl-top-0', 'gl-right-3']);
  });

  it('loads code block’s syntax highlight language', async () => {
    createWrapper();

    expect(codeBlockLanguageLoader.loadLanguage).toHaveBeenCalledWith(language);

    await nextTick();

    expect(updateAttributesFn).toHaveBeenCalledWith({ language });
  });

  describe('diagrams', () => {
    beforeEach(() => {
      jest.spyOn(tiptapEditor, 'isActive').mockReturnValue(true);
    });

    it('does not render a preview if showPreview: false', () => {
      createWrapper({ language: 'plantuml', isDiagram: true, showPreview: false });

      expect(wrapper.findComponent({ ref: 'diagramContainer' }).exists()).toBe(false);
    });

    it('does not update preview when diagram is not active', async () => {
      createWrapper({ language: 'plantuml', isDiagram: true, showPreview: true });

      await emitEditorEvent({ event: 'transaction', tiptapEditor });
      await nextTick();

      expect(wrapper.find('img').attributes('src')).toBe('url/to/some/diagram');

      jest.spyOn(tiptapEditor, 'isActive').mockReturnValue(false);

      const alternateUrl = 'url/to/another/diagram';

      contentEditor.renderDiagram.mockResolvedValue(alternateUrl);

      await emitEditorEvent({ event: 'transaction', tiptapEditor });
      await nextTick();

      expect(wrapper.find('img').attributes('src')).toBe('url/to/some/diagram');
    });

    it('renders an image with preview for a plantuml/kroki diagram', async () => {
      createWrapper({ language: 'plantuml', isDiagram: true, showPreview: true });

      await emitEditorEvent({ event: 'transaction', tiptapEditor });
      await nextTick();

      expect(wrapper.find('img').attributes('src')).toBe('url/to/some/diagram');
      expect(wrapper.findComponent(SandboxedMermaid).exists()).toBe(false);
    });

    it('renders an iframe with preview for a mermaid diagram', async () => {
      createWrapper({ language: 'mermaid', isDiagram: true, showPreview: true });

      await emitEditorEvent({ event: 'transaction', tiptapEditor });
      await nextTick();

      expect(wrapper.findComponent(SandboxedMermaid).props('source')).toBe('');
      expect(wrapper.find('img').exists()).toBe(false);
    });
  });
});
