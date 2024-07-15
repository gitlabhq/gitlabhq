import { builders } from 'prosemirror-test-builder';
import Diagram from '~/content_editor/extensions/diagram';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import { createTestEditor } from '../test_utils';

const DIAGRAM_HTML = `<div class="gl-relative markdown-code-block js-markdown-code">&#x000A;<pre data-sourcepos="1:1-5:3" data-canonical-lang="mermaid" class="code highlight js-syntax-highlight language-mermaid" v-pre="true"><code class="js-render-mermaid"><span id="LC1" class="line" lang="mermaid">pie title NETFLIX</span>&#x000A;<span id="LC2" class="line" lang="mermaid">  "Time spent looking for movie" : 90</span>&#x000A;<span id="LC3" class="line" lang="mermaid">  "Time spent watching it" : 10</span></code></pre>&#x000A;<copy-code></copy-code>&#x000A;</div>`;

describe('content_editor/extensions/diagram', () => {
  let tiptapEditor;
  let doc;
  let diagram;

  const createEditor = () => {
    tiptapEditor = createTestEditor({
      extensions: [CodeBlockHighlight, Diagram],
    });

    ({ doc, diagram } = builders(tiptapEditor.schema));
  };

  it('inherits from code block highlight extension', () => {
    expect(Diagram.parent).toBe(CodeBlockHighlight);
  });

  it('sets isDiagram attribute to true by default', () => {
    expect(Diagram.config.addAttributes()).toEqual(
      expect.objectContaining({
        isDiagram: { default: true },
      }),
    );
  });

  describe('when parsing HTML', () => {
    beforeEach(() => {
      createEditor();

      tiptapEditor.commands.setContent(DIAGRAM_HTML);
    });

    it('parses HTML correctly into a diagram block', () => {
      expect(tiptapEditor.getJSON()).toEqual(
        doc(
          diagram(
            { language: 'mermaid' },
            'pie title NETFLIX  "Time spent looking for movie" : 90  "Time spent watching it" : 10',
          ),
        ).toJSON(),
      );
    });
  });
});
