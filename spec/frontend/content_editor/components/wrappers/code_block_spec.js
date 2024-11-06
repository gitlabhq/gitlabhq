import { nextTick } from 'vue';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import eventHubFactory from '~/helpers/event_hub_factory';
import SandboxedMermaid from '~/behaviors/components/sandboxed_mermaid.vue';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import Diagram from '~/content_editor/extensions/diagram';
import CodeSuggestion from '~/content_editor/extensions/code_suggestion';
import CodeBlockWrapper from '~/content_editor/components/wrappers/code_block.vue';
import codeBlockLanguageLoader from '~/content_editor/services/code_block_language_loader';
import { emitEditorEvent, createTestEditor, mockChainedCommands } from '../../test_utils';

// Disabled due to eslint reporting errors for inline snapshots
/* eslint-disable no-irregular-whitespace */

const SAMPLE_README_CONTENT = `# Sample README

This is a sample README.

## Usage

\`\`\`yaml
foo: bar
\`\`\`
`;

jest.mock('~/content_editor/services/code_block_language_loader');
jest.mock('~/content_editor/services/utils', () => ({
  memoizedGet: jest.fn().mockResolvedValue(SAMPLE_README_CONTENT),
}));

describe('content/components/wrappers/code_block', () => {
  const language = 'yaml';
  let wrapper;
  let updateAttributesFn;
  let tiptapEditor;
  let contentEditor;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({ extensions: [CodeBlockHighlight, Diagram, CodeSuggestion] });
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

    const label = wrapper.findByTestId('frontmatter-label');

    expect(label.text()).toEqual('frontmatter:yaml');
    expect(label.attributes('contenteditable')).toBe('false');
    expect(label.classes()).toEqual(['gl-absolute', 'gl-right-3', 'gl-top-0']);
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
      expect(wrapper.findByTestId('sandbox-preview').attributes('contenteditable')).toBe(
        String(false),
      );

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

  describe('code suggestions', () => {
    const nodeAttrs = { language: 'suggestion', isCodeSuggestion: true, langParams: '-0+0' };
    const findCodeSuggestionBoxText = () =>
      wrapper.findByTestId('code-suggestion-box').text().replace(/\s+/gm, ' ');
    const findCodeDeleted = () =>
      wrapper
        .findByTestId('suggestion-deleted')
        .findAll('code')
        .wrappers.map((w) => w.html())
        .join('\n');
    const findCodeAdded = () =>
      wrapper
        .findByTestId('suggestion-added')
        .findAll('code')
        .wrappers.map((w) => w.html())
        .join('\n');

    let commands;

    const clickButton = async ({ button, expectedLangParams }) => {
      await button.trigger('click');

      expect(commands.updateAttributes).toHaveBeenCalledWith('codeSuggestion', {
        langParams: expectedLangParams,
      });
      expect(commands.run).toHaveBeenCalled();

      await wrapper.setProps({ node: { attrs: { ...nodeAttrs, langParams: expectedLangParams } } });
      await emitEditorEvent({ event: 'transaction', tiptapEditor });
    };

    beforeEach(async () => {
      contentEditor = {
        codeSuggestionsConfig: {
          canSuggest: true,
          line: { new_line: 5 },
          lines: [{ new_line: 5 }],
          showPopover: false,
          diffFile: {
            view_path:
              '/gitlab-org/gitlab-test/-/blob/468abc807a2b2572f43e72c743b76cee6db24025/README.md',
          },
        },
      };

      commands = mockChainedCommands(tiptapEditor, ['updateAttributes', 'run']);

      createWrapper(nodeAttrs);
      await emitEditorEvent({ event: 'transaction', tiptapEditor });
    });

    it('shows a code suggestion block', () => {
      expect(wrapper.findByTestId('code-suggestion-box').attributes('contenteditable')).toBe(
        'false',
      );
      expect(findCodeSuggestionBoxText()).toContain('Suggested change From line 5 to 5');
      expect(findCodeDeleted()).toMatchInlineSnapshot(`
<code
  class="!gl-border-transparent diff-line-num"
  data-line-number="5"
>
  <span
    class="line_holder"
  >
    <span
      class="line_content old"
    >
      ## Usage​
    </span>
  </span>
</code>
`);
      expect(findCodeAdded()).toMatchInlineSnapshot(`
<code
  class="!gl-border-transparent diff-line-num"
  data-line-number="5"
>
  <span
    class="line_holder"
  >
    <span
      class="!gl-text-transparent line_content new"
    >
      ​
    </span>
  </span>
</code>
`);
    });

    describe('decrement line start button', () => {
      let button;

      beforeEach(() => {
        button = wrapper.findByTestId('decrement-line-start');
      });

      it('decrements the start line number', async () => {
        await clickButton({ button, expectedLangParams: '-1+0' });

        expect(findCodeSuggestionBoxText()).toContain('Suggested change From line 4 to 5');
        expect(findCodeDeleted()).toMatchInlineSnapshot(`
<code
  class="!gl-border-transparent diff-line-num"
  data-line-number="4"
>
  <span
    class="line_holder"
  >
    <span
      class="line_content old"
    >
      ​
    </span>
  </span>
</code>
`);
      });

      it('is disabled if the start line is already 1', async () => {
        expect(button.attributes('disabled')).toBeUndefined();

        await clickButton({ button, expectedLangParams: '-1+0' });
        await clickButton({ button, expectedLangParams: '-2+0' });
        await clickButton({ button, expectedLangParams: '-3+0' });
        await clickButton({ button, expectedLangParams: '-4+0' });

        expect(findCodeSuggestionBoxText()).toContain('Suggested change From line 1 to 5');
        expect(findCodeDeleted()).toMatchInlineSnapshot(`
<code
  class="!gl-border-transparent diff-line-num"
  data-line-number="1"
>
  <span
    class="line_holder"
  >
    <span
      class="line_content old"
    >
      # Sample README​
    </span>
  </span>
</code>
`);

        expect(button.attributes('disabled')).toBe('disabled');
      });
    });

    describe('increment line start button', () => {
      let decrementButton;
      let button;

      beforeEach(() => {
        decrementButton = wrapper.findByTestId('decrement-line-start');
        button = wrapper.findByTestId('increment-line-start');
      });

      it('is disabled if the start line is already the current line', async () => {
        expect(button.attributes('disabled')).toBe('disabled');

        // decrement once, increment once
        await clickButton({ button: decrementButton, expectedLangParams: '-1+0' });
        expect(button.attributes('disabled')).toBeUndefined();
        await clickButton({ button, expectedLangParams: '-0+0' });

        expect(button.attributes('disabled')).toBe('disabled');
      });

      it('increments the start line number', async () => {
        // decrement twice, increment once
        await clickButton({ button: decrementButton, expectedLangParams: '-1+0' });
        await clickButton({ button: decrementButton, expectedLangParams: '-2+0' });
        await clickButton({ button, expectedLangParams: '-1+0' });

        expect(findCodeSuggestionBoxText()).toContain('Suggested change From line 4 to 5');
        expect(findCodeDeleted()).toMatchInlineSnapshot(`
<code
  class="!gl-border-transparent diff-line-num"
  data-line-number="4"
>
  <span
    class="line_holder"
  >
    <span
      class="line_content old"
    >
      ​
    </span>
  </span>
</code>
`);
      });
    });

    describe('decrement line end button', () => {
      let incrementButton;
      let button;

      beforeEach(() => {
        incrementButton = wrapper.findByTestId('increment-line-end');
        button = wrapper.findByTestId('decrement-line-end');
      });

      it('is disabled if the line end is already the current line', async () => {
        expect(button.attributes('disabled')).toBe('disabled');

        // increment once, decrement once
        await clickButton({ button: incrementButton, expectedLangParams: '-0+1' });
        expect(button.attributes('disabled')).toBeUndefined();
        await clickButton({ button, expectedLangParams: '-0+0' });

        expect(button.attributes('disabled')).toBe('disabled');
      });

      it('increments the end line number', async () => {
        // increment twice, decrement once
        await clickButton({ button: incrementButton, expectedLangParams: '-0+1' });
        await clickButton({ button: incrementButton, expectedLangParams: '-0+2' });
        await clickButton({ button, expectedLangParams: '-0+1' });

        expect(findCodeSuggestionBoxText()).toContain('Suggested change From line 5 to 6');
        expect(findCodeDeleted()).toMatchInlineSnapshot(`
<code
  class="!gl-border-transparent diff-line-num"
  data-line-number="5"
>
  <span
    class="line_holder"
  >
    <span
      class="line_content old"
    >
      ## Usage​
    </span>
  </span>
</code>
`);
      });
    });

    describe('increment line end button', () => {
      let button;

      beforeEach(() => {
        button = wrapper.findByTestId('increment-line-end');
      });

      it('decrements the start line number', async () => {
        await clickButton({ button, expectedLangParams: '-0+1' });

        expect(findCodeSuggestionBoxText()).toContain('Suggested change From line 5 to 6');
        expect(findCodeDeleted()).toMatchInlineSnapshot(`
<code
  class="!gl-border-transparent diff-line-num"
  data-line-number="5"
>
  <span
    class="line_holder"
  >
    <span
      class="line_content old"
    >
      ## Usage​
    </span>
  </span>
</code>
`);
      });

      it('is disabled if the end line is EOF', async () => {
        expect(button.attributes('disabled')).toBeUndefined();

        await clickButton({ button, expectedLangParams: '-0+1' });
        await clickButton({ button, expectedLangParams: '-0+2' });
        await clickButton({ button, expectedLangParams: '-0+3' });
        await clickButton({ button, expectedLangParams: '-0+4' });

        expect(findCodeSuggestionBoxText()).toContain('Suggested change From line 5 to 9');
        expect(findCodeDeleted()).toMatchInlineSnapshot(`
<code
  class="!gl-border-transparent diff-line-num"
  data-line-number="5"
>
  <span
    class="line_holder"
  >
    <span
      class="line_content old"
    >
      ## Usage​
    </span>
  </span>
</code>
`);

        expect(button.attributes('disabled')).toBe('disabled');
      });
    });
  });
});
