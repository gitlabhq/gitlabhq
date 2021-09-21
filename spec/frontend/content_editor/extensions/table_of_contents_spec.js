import TableOfContents from '~/content_editor/extensions/table_of_contents';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/emoji', () => {
  let tiptapEditor;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [TableOfContents] });
  });

  it.each`
    input          | insertedNodeName
    ${'[[_TOC_]]'} | ${TableOfContents.name}
    ${'[TOC]'}     | ${TableOfContents.name}
    ${'[toc]'}     | ${'paragraph'}
    ${'TOC'}       | ${'paragraph'}
    ${'[_TOC_]'}   | ${'paragraph'}
    ${'[[TOC]]'}   | ${'paragraph'}
  `('with input=$input, then should insert a $insertedNodeName', ({ input, insertedNodeName }) => {
    const { view } = tiptapEditor;
    const { selection } = view.state;

    // Triggers the event handler that input rules listen to
    view.someProp('handleTextInput', (f) => f(view, selection.from, selection.to, input));

    expect(tiptapEditor.state.doc.content.content).toEqual([
      expect.objectContaining({
        type: expect.objectContaining({
          name: insertedNodeName,
        }),
      }),
    ]);
  });
});
