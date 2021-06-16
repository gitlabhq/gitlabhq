import { tiptapExtension as CodeBlockHighlight } from '~/content_editor/extensions/code_block_highlight';
import { loadMarkdownApiResult } from '../markdown_processing_examples';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/code_block_highlight', () => {
  let codeBlockHtmlFixture;
  let parsedCodeBlockHtmlFixture;
  let tiptapEditor;

  const parseHTML = (html) => new DOMParser().parseFromString(html, 'text/html');
  const preElement = () => parsedCodeBlockHtmlFixture.querySelector('pre');

  beforeEach(() => {
    const { html } = loadMarkdownApiResult('code_block');

    tiptapEditor = createTestEditor({ extensions: [CodeBlockHighlight] });
    codeBlockHtmlFixture = html;
    parsedCodeBlockHtmlFixture = parseHTML(codeBlockHtmlFixture);

    tiptapEditor.commands.setContent(codeBlockHtmlFixture);
  });

  it('extracts language and params attributes from Markdown API output', () => {
    const language = preElement().getAttribute('lang');

    expect(tiptapEditor.getJSON().content[0].attrs).toMatchObject({
      language,
      params: language,
    });
  });

  it('adds code, highlight, and js-syntax-highlight to code block element', () => {
    const editorHtmlOutput = parseHTML(tiptapEditor.getHTML()).querySelector('pre');

    expect(editorHtmlOutput.classList.toString()).toContain('code highlight js-syntax-highlight');
  });
});
