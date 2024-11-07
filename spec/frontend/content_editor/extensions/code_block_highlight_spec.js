import { builders } from 'prosemirror-test-builder';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import languageLoader from '~/content_editor/services/code_block_language_loader';
import { createTestEditor, triggerNodeInputRule } from '../test_utils';

const CODE_BLOCK_HTML = `<div class="gl-relative markdown-code-block js-markdown-code">&#x000A;<pre data-sourcepos="1:1-3:3" data-canonical-lang="javascript" class="code highlight js-syntax-highlight language-javascript" v-pre="true"><code><span id="LC1" class="line" lang="javascript"><span class="nx">console</span><span class="p">.</span><span class="nf">log</span><span class="p">(</span><span class="dl">'</span><span class="s1">hello world</span><span class="dl">'</span><span class="p">)</span></span></code></pre>&#x000A;<copy-code></copy-code>&#x000A;</div>`;
const EMPTY_CODE_BLOCK_HTML = `<div class="gl-relative markdown-code-block js-markdown-code">&#x000A;<pre class="code highlight js-syntax-highlight language-javascript" data-canonical-lang="js" data-sourcepos="1:1-2:3"><code></code></pre>&#x000A;&#x000A;</div>`;

jest.mock('~/content_editor/services/code_block_language_loader');

describe('content_editor/extensions/code_block_highlight', () => {
  let tiptapEditor;
  let doc;
  let codeBlock;

  beforeEach(() => {
    tiptapEditor = createTestEditor({
      extensions: [CodeBlockHighlight],
    });

    ({ doc, codeBlock } = builders(tiptapEditor.schema));
  });

  describe('when parsing HTML', () => {
    beforeEach(() => {
      tiptapEditor.commands.setContent(CODE_BLOCK_HTML);
    });

    it('parses HTML correctly into a code block', () => {
      expect(tiptapEditor.getJSON()).toEqual(
        doc(
          codeBlock(
            {
              language: 'javascript',
              class: 'code highlight js-syntax-highlight language-javascript',
            },
            "console.log('hello world')",
          ),
        ).toJSON(),
      );
    });

    it('includes the lowlight plugin', () => {
      expect(tiptapEditor.state.plugins).toContainEqual(
        expect.objectContaining({ key: expect.stringContaining('lowlight') }),
      );
    });

    it('does not include the VSCode paste plugin', () => {
      expect(tiptapEditor.state.plugins).not.toContainEqual(
        expect.objectContaining({ key: expect.stringContaining('VSCode') }),
      );
    });
  });

  it('correctly parses HTML with empty code block', () => {
    tiptapEditor.commands.setContent(EMPTY_CODE_BLOCK_HTML);

    expect(tiptapEditor.getJSON()).toEqual(
      doc(
        codeBlock(
          {
            language: 'js',
            class: 'code highlight js-syntax-highlight language-javascript',
          },
          '',
        ),
      ).toJSON(),
    );
  });

  describe.each`
    inputRule
    ${'```'}
    ${'~~~'}
  `('when typing $inputRule input rule', ({ inputRule }) => {
    const language = 'javascript';

    beforeEach(() => {
      languageLoader.loadLanguageFromInputRule.mockReturnValueOnce({ language });

      triggerNodeInputRule({
        tiptapEditor,
        inputRuleText: `${inputRule}${language} `,
      });
    });

    it('creates a new code block and loads related language', () => {
      const expectedDoc = doc(codeBlock({ language }));

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });

    it('loads language when language loader is available', () => {
      expect(languageLoader.loadLanguageFromInputRule).toHaveBeenCalledWith(
        expect.arrayContaining([`${inputRule}${language} `, language]),
      );
    });
  });
});
