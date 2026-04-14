import { builders } from 'prosemirror-test-builder';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import CodeSuggestion from '~/content_editor/extensions/code_suggestion';
import {
  createTestEditor,
  triggerNodeInputRule,
  expectDocumentAfterTransaction,
  sleep,
} from '../test_utils';

const CODE_SUGGESTION_HTML = `<div class="gl-relative markdown-code-block js-markdown-code"><pre data-sourcepos="1:1-3:3" data-canonical-lang="suggestion" data-lang-params="-0+0" class="code highlight js-syntax-highlight language-suggestion" v-pre="true"><code class="js-render-suggestion"><span id="LC1" class="line" lang="suggestion">    options = [</span></code></pre></div>`;

const EMPTY_CODE_SUGGESTION_HTML = `<div class="gl-relative markdown-code-block js-markdown-code"><pre data-sourcepos="1:1-2:3" data-canonical-lang="suggestion" data-lang-params="-0+0" class="code highlight js-syntax-highlight language-suggestion" v-pre="true"><code class="js-render-suggestion"></code></pre></div>`;

describe('content_editor/extensions/code_suggestion', () => {
  let tiptapEditor;
  let doc;
  let codeSuggestion;

  const createEditor = (config = {}) => {
    tiptapEditor = createTestEditor({
      extensions: [
        CodeBlockHighlight,
        CodeSuggestion.configure({
          codeSuggestionsConfig: { canSuggest: true, showPopover: false, ...config },
        }),
      ],
    });

    ({ doc, codeSuggestion } = builders(tiptapEditor.schema));
  };

  describe('insertCodeSuggestion command', () => {
    it('uses pre-fetched lines directly when provided', async () => {
      createEditor({ lines: ['## Usage'] });

      await expectDocumentAfterTransaction({
        number: 1,
        tiptapEditor,
        action: () => tiptapEditor.commands.insertCodeSuggestion(),
        expectedDoc: doc(codeSuggestion({ langParams: '-0+0' }, '## Usage')),
      });
    });

    it('creates a correct suggestion for a multi-line selection via lines', async () => {
      createEditor({ lines: ['## Usage', '', '```yaml', 'foo: bar', '```'] });

      await expectDocumentAfterTransaction({
        number: 1,
        tiptapEditor,
        action: () => tiptapEditor.commands.insertCodeSuggestion(),
        expectedDoc: doc(
          codeSuggestion({ langParams: '-4+0' }, '## Usage\n\n```yaml\nfoo: bar\n```'),
        ),
      });
    });

    it('creates an empty suggestion when no lines are provided', async () => {
      createEditor({ lines: [] });

      await expectDocumentAfterTransaction({
        number: 1,
        tiptapEditor,
        action: () => tiptapEditor.commands.insertCodeSuggestion(),
        // empty strings are not allowed in ProseMirror text nodes, so a space is used
        expectedDoc: doc(codeSuggestion({ langParams: '-0+0' }, ' ')),
      });
    });

    it('does not insert a new suggestion if already inside a suggestion', async () => {
      const initialDoc = codeSuggestion({ langParams: '-0+0' }, '## Usage');

      createEditor({ lines: ['## Usage'] });

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

  describe('when parsing HTML with an empty code suggestion', () => {
    beforeEach(() => {
      createEditor();

      tiptapEditor.commands.setContent(EMPTY_CODE_SUGGESTION_HTML);
    });

    it('parses HTML correctly into a code suggestions block', () => {
      expect(tiptapEditor.getJSON()).toEqual(
        doc(
          codeSuggestion({
            language: 'suggestion',
            langParams: '-0+0',
            class: 'code highlight js-syntax-highlight language-suggestion',
          }),
        ).toJSON(),
      );
    });
  });
});
