import { builders } from 'prosemirror-test-builder';
import Details from '~/content_editor/extensions/details';
import DetailsContent from '~/content_editor/extensions/details_content';
import { createTestEditor, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/details', () => {
  let tiptapEditor;
  let doc;
  let p;
  let details;
  let detailsContent;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Details, DetailsContent] });

    ({ doc, paragraph: p, details, detailsContent } = builders(tiptapEditor.schema));
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
    inputRuleText  | insertedNode                          | insertedNodeType
    ${'<details>'} | ${() => details(detailsContent(p()))} | ${'details'}
    ${'<details'}  | ${() => p()}                          | ${'paragraph'}
    ${'details>'}  | ${() => p()}                          | ${'paragraph'}
  `('with input=$input, it inserts a $insertedNodeType node', ({ inputRuleText, insertedNode }) => {
    triggerNodeInputRule({ tiptapEditor, inputRuleText });

    expect(tiptapEditor.getJSON()).toEqual(doc(insertedNode()).toJSON());
  });
});
