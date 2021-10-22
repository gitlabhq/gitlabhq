import TableOfContents from '~/content_editor/extensions/table_of_contents';
import { createTestEditor, createDocBuilder, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/table_of_contents', () => {
  let tiptapEditor;
  let doc;
  let tableOfContents;
  let p;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [TableOfContents] });
    ({
      builders: { doc, p, tableOfContents },
    } = createDocBuilder({
      tiptapEditor,
      names: { tableOfContents: { nodeType: TableOfContents.name } },
    }));
  });

  it.each`
    input          | insertedNode
    ${'[[_TOC_]]'} | ${() => tableOfContents()}
    ${'[TOC]'}     | ${() => tableOfContents()}
    ${'[toc]'}     | ${() => p()}
    ${'TOC'}       | ${() => p()}
    ${'[_TOC_]'}   | ${() => p()}
    ${'[[TOC]]'}   | ${() => p()}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNode }) => {
    const expectedDoc = doc(insertedNode());

    triggerNodeInputRule({ tiptapEditor, inputRuleText: input });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
