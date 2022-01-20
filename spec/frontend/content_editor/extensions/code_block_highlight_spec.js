import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import { createTestEditor } from '../test_utils';

const CODE_BLOCK_HTML = `<pre class="code highlight js-syntax-highlight language-javascript" lang="javascript" v-pre="true">
  <code>
    <span id="LC1" class="line" lang="javascript">
      <span class="nx">console</span><span class="p">.</span><span class="nx">log</span><span class="p">(</span><span class="dl">'</span><span class="s1">hello world</span><span class="dl">'</span><span class="p">)</span>
    </span>
  </code>
</pre>`;

describe('content_editor/extensions/code_block_highlight', () => {
  let parsedCodeBlockHtmlFixture;
  let tiptapEditor;

  const parseHTML = (html) => new DOMParser().parseFromString(html, 'text/html');
  const preElement = () => parsedCodeBlockHtmlFixture.querySelector('pre');

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [CodeBlockHighlight] });
    parsedCodeBlockHtmlFixture = parseHTML(CODE_BLOCK_HTML);

    tiptapEditor.commands.setContent(CODE_BLOCK_HTML);
  });

  it('extracts language and params attributes from Markdown API output', () => {
    const language = preElement().getAttribute('lang');

    expect(tiptapEditor.getJSON().content[0].attrs).toMatchObject({
      language,
    });
  });

  it('adds code, highlight, and js-syntax-highlight to code block element', () => {
    const editorHtmlOutput = parseHTML(tiptapEditor.getHTML()).querySelector('pre');

    expect(editorHtmlOutput.classList.toString()).toContain('code highlight js-syntax-highlight');
  });

  it('adds content-editor-code-block class to the pre element', () => {
    const editorHtmlOutput = parseHTML(tiptapEditor.getHTML()).querySelector('pre');

    expect(editorHtmlOutput.classList.toString()).toContain('content-editor-code-block');
  });
});
