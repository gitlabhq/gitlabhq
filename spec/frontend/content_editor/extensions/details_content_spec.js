import Details from '~/content_editor/extensions/details';
import DetailsContent from '~/content_editor/extensions/details_content';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/extensions/details_content', () => {
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

  describe('shortcut: Enter', () => {
    it('splits a details content into two items', () => {
      const initialDoc = doc(
        details(
          detailsContent(p('Summary')),
          detailsContent(p('Text content')),
          detailsContent(p('Text content')),
        ),
      );
      const expectedDoc = doc(
        details(
          detailsContent(p('Summary')),
          detailsContent(p('')),
          detailsContent(p('Text content')),
          detailsContent(p('Text content')),
        ),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());

      tiptapEditor.commands.setTextSelection(10);
      tiptapEditor.commands.keyboardShortcut('Enter');

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });

  describe('shortcut: Shift-Tab', () => {
    it('lifts a details content and creates two separate details items', () => {
      const initialDoc = doc(
        details(
          detailsContent(p('Summary')),
          detailsContent(p('Text content')),
          detailsContent(p('Text content')),
        ),
      );
      const expectedDoc = doc(
        details(detailsContent(p('Summary'))),
        p('Text content'),
        details(detailsContent(p('Text content'))),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());

      tiptapEditor.commands.setTextSelection(20);
      tiptapEditor.commands.keyboardShortcut('Shift-Tab');

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });
});
