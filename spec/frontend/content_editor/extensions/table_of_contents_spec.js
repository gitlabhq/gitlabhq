import TableOfContents from '~/content_editor/extensions/table_of_contents';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/extensions/emoji', () => {
  let tiptapEditor;
  let builders;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [TableOfContents] });
    ({ builders } = createDocBuilder({
      tiptapEditor,
      names: { tableOfContents: { nodeType: TableOfContents.name } },
    }));
  });

  it.each`
    input          | insertedNode
    ${'[[_TOC_]]'} | ${'tableOfContents'}
    ${'[TOC]'}     | ${'tableOfContents'}
    ${'[toc]'}     | ${'p'}
    ${'TOC'}       | ${'p'}
    ${'[_TOC_]'}   | ${'p'}
    ${'[[TOC]]'}   | ${'p'}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNode }) => {
    const { doc } = builders;
    const { view } = tiptapEditor;
    const { selection } = view.state;
    const expectedDoc = doc(builders[insertedNode]());

    // Triggers the event handler that input rules listen to
    view.someProp('handleTextInput', (f) => f(view, selection.from, selection.to, input));

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
