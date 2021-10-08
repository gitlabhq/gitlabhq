import Details from '~/content_editor/extensions/details';
import DetailsContent from '~/content_editor/extensions/details_content';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/extensions/details', () => {
  let tiptapEditor;
  let doc;
  let p;
  let details;
  let detailsContent;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Details, DetailsContent] });

    ({
      builders: { doc, p, details, detailsContent },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        details: { nodeType: Details.name },
        detailsContent: { nodeType: DetailsContent.name },
      },
    }));
  });

  describe('setDetails command', () => {
    describe('when current block is a paragraph', () => {
      it('converts current paragraph into a details block', () => {
        const initialDoc = doc(p('Text content'));
        const expectedDoc = doc(details(detailsContent(p('Text content'))));

        tiptapEditor.commands.setContent(initialDoc.toJSON());
        tiptapEditor.commands.setDetails();

        expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when current block is a details block', () => {
      it('maintains the same document structure', () => {
        const initialDoc = doc(details(detailsContent(p('Text content'))));

        tiptapEditor.commands.setContent(initialDoc.toJSON());
        tiptapEditor.commands.setDetails();

        expect(tiptapEditor.getJSON()).toEqual(initialDoc.toJSON());
      });
    });
  });

  describe('toggleDetails command', () => {
    describe('when current block is a paragraph', () => {
      it('converts current paragraph into a details block', () => {
        const initialDoc = doc(p('Text content'));
        const expectedDoc = doc(details(detailsContent(p('Text content'))));

        tiptapEditor.commands.setContent(initialDoc.toJSON());
        tiptapEditor.commands.toggleDetails();

        expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when current block is a details block', () => {
      it('convert details block into a paragraph', () => {
        const initialDoc = doc(details(detailsContent(p('Text content'))));
        const expectedDoc = doc(p('Text content'));

        tiptapEditor.commands.setContent(initialDoc.toJSON());
        tiptapEditor.commands.toggleDetails();

        expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
      });
    });
  });

  it.each`
    input          | insertedNode
    ${'<details>'} | ${(...args) => details(detailsContent(p(...args)))}
    ${'<details'}  | ${(...args) => p(...args)}
    ${'details>'}  | ${(...args) => p(...args)}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNode }) => {
    const { view } = tiptapEditor;
    const { selection } = view.state;
    const expectedDoc = doc(insertedNode());

    // Triggers the event handler that input rules listen to
    view.someProp('handleTextInput', (f) => f(view, selection.from, selection.to, input));

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
