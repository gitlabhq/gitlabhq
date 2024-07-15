import { builders } from 'prosemirror-test-builder';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import CodeSuggestion from '~/content_editor/extensions/code_suggestion';
import {
  createTestEditor,
  triggerNodeInputRule,
  expectDocumentAfterTransaction,
  sleep,
} from '../test_utils';

const SAMPLE_README_CONTENT = `# Sample README

This is a sample README.

## Usage

\`\`\`yaml
foo: bar
\`\`\`
`;

const CODE_SUGGESTION_HTML = `<div class="gl-relative markdown-code-block js-markdown-code"><pre data-sourcepos="1:1-3:3" data-canonical-lang="suggestion" data-lang-params="-0+0" class="code highlight js-syntax-highlight language-suggestion" v-pre="true"><code class="js-render-suggestion"><span id="LC1" class="line" lang="suggestion">    options = [</span></code></pre></div>`;

jest.mock('~/content_editor/services/utils', () => ({
  memoizedGet: jest.fn().mockResolvedValue(SAMPLE_README_CONTENT),
}));

describe('content_editor/extensions/code_suggestion', () => {
  let tiptapEditor;
  let doc;
  let codeSuggestion;

  const codeSuggestionsConfig = {
    canSuggest: true,
    line: { new_line: 5 },
    lines: [{ new_line: 5 }],
    showPopover: false,
    diffFile: {
      view_path:
        '/gitlab-org/gitlab-test/-/blob/468abc807a2b2572f43e72c743b76cee6db24025/README.md',
    },
  };

  const createEditor = (config = {}) => {
    tiptapEditor = createTestEditor({
      extensions: [
        CodeBlockHighlight,
        CodeSuggestion.configure({
          codeSuggestionsConfig: { ...codeSuggestionsConfig, ...config },
        }),
      ],
    });

    ({ doc, codeSuggestion } = builders(tiptapEditor.schema));
  };

  describe('insertCodeSuggestion command', () => {
    it('creates a correct suggestion for a single line selection', async () => {
      createEditor({ line: { new_line: 5 }, lines: [] });

      await expectDocumentAfterTransaction({
        number: 1,
        tiptapEditor,
        action: () => tiptapEditor.commands.insertCodeSuggestion(),
        expectedDoc: doc(codeSuggestion({ langParams: '-0+0' }, '## Usage')),
      });
    });

    it('creates a correct suggestion for a multi-line selection', async () => {
      createEditor({
        line: { new_line: 9 },
        lines: [
          { new_line: 5 },
          { new_line: 6 },
          { new_line: 7 },
          { new_line: 8 },
          { new_line: 9 },
        ],
      });

      await expectDocumentAfterTransaction({
        number: 1,
        tiptapEditor,
        action: () => tiptapEditor.commands.insertCodeSuggestion(),
        expectedDoc: doc(
          codeSuggestion({ langParams: '-4+0' }, '## Usage\n\n```yaml\nfoo: bar\n```'),
        ),
      });
    });

    it('does not insert a new suggestion if already inside a suggestion', async () => {
      const initialDoc = codeSuggestion({ langParams: '-0+0' }, '## Usage');

      createEditor({ line: { new_line: 5 }, lines: [] });

      tiptapEditor.commands.setContent(doc(initialDoc).toJSON());

      jest.spyOn(tiptapEditor, 'isActive').mockReturnValue(true);

      tiptapEditor.commands.insertCodeSuggestion();
      // wait some time to be sure no other transaction happened
      await sleep();

      expect(tiptapEditor.getJSON()).toEqual(doc(initialDoc).toJSON());
    });
  });

  describe('when typing ```suggestion input rule', () => {
    beforeEach(() => {
      createEditor();

      triggerNodeInputRule({
        tiptapEditor,
        inputRuleText: '```suggestion ',
      });
    });

    it('creates a new code suggestion block with lines -0+0', () => {
      const expectedDoc = doc(codeSuggestion({ language: 'suggestion', langParams: '-0+0' }));

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });

  describe('when parsing HTML', () => {
    beforeEach(() => {
      createEditor();

      tiptapEditor.commands.setContent(CODE_SUGGESTION_HTML);
    });

    it('parses HTML correctly into a code suggestions block', () => {
      expect(tiptapEditor.getJSON()).toEqual(
        doc(
          codeSuggestion(
            {
              language: 'suggestion',
              langParams: '-0+0',
              class: 'code highlight js-syntax-highlight language-suggestion',
            },
            '    options = [',
          ),
        ).toJSON(),
      );
    });
  });
});
