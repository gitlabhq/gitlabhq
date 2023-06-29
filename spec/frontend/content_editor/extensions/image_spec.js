import Image from '~/content_editor/extensions/image';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/extensions/image', () => {
  let tiptapEditor;
  let doc;
  let p;
  let image;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Image] });

    ({
      builders: { doc, p, image },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        image: { nodeType: Image.name },
      },
    }));
  });

  it('adds data-canonical-src attribute when rendering to HTML', () => {
    const initialDoc = doc(
      p(
        image({
          canonicalSrc: 'uploads/image.jpg',
          src: '/-/wikis/uploads/image.jpg',
          alt: 'image',
          title: 'this is an image',
        }),
      ),
    );

    tiptapEditor.commands.setContent(initialDoc.toJSON());

    expect(tiptapEditor.getHTML()).toEqual(
      '<p dir="auto"><img src="/-/wikis/uploads/image.jpg" alt="image" title="this is an image"></p>',
    );
  });
});
