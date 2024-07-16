import { builders } from 'prosemirror-test-builder';
import Image from '~/content_editor/extensions/image';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/image', () => {
  let tiptapEditor;
  let doc;
  let p;
  let image;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Image] });

    ({ doc, paragraph: p, image } = builders(tiptapEditor.schema));
  });

  it('sets the draggable option to true', () => {
    expect(Image.config.draggable).toBe(true);
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
