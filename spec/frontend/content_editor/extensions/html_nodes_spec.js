import HTMLNodes from '~/content_editor/extensions/html_nodes';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/extensions/html_nodes', () => {
  let tiptapEditor;
  let doc;
  let div;
  let pre;
  let p;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [...HTMLNodes] });

    ({
      builders: { doc, p, pre, div },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        ...HTMLNodes.reduce(
          (builders, htmlNode) => ({
            ...builders,
            [htmlNode.name]: { nodeType: htmlNode.name },
          }),
          {},
        ),
      },
    }));
  });

  it.each`
    input                                 | insertedNodes
    ${'<div><p dir="auto">foo</p></div>'} | ${() => div(p('foo'))}
    ${'<pre><p dir="auto">foo</p></pre>'} | ${() => pre(p('foo'))}
  `('parses and creates nodes for $input', ({ input, insertedNodes }) => {
    const expectedDoc = doc(insertedNodes());

    tiptapEditor.commands.setContent(input);

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    expect(tiptapEditor.getHTML()).toEqual(input);
  });
});
