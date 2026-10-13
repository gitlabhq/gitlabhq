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

  describe('when parsing HTML', () => {
    describe('when the image has a data-placeholder attribute', () => {
      it('decodes percent-encoded placeholders in the canonical src', () => {
        tiptapEditor.commands.setContent(
          '<img src="http://localhost/foo.png" alt="image" data-placeholder ' +
            'data-canonical-src="http://%25%7Bgitlab_server%7D/foo.png">',
        );

        expect(tiptapEditor.getJSON()).toEqual(
          doc(
            p(
              image({
                src: 'http://localhost/foo.png',
                canonicalSrc: 'http://%{gitlab_server}/foo.png',
                alt: 'image',
              }),
            ),
          ).toJSON(),
        );
      });

      it('decodes when the image is wrapped in a link', () => {
        tiptapEditor.commands.setContent(
          '<a class="no-attachment-icon" href="http://localhost/foo.png" data-placeholder ' +
            'data-canonical-src="http://%25%7Bgitlab_server%7D/foo.png">' +
            '<img src="http://localhost/foo.png" alt="image" data-placeholder ' +
            'data-canonical-src="http://%25%7Bgitlab_server%7D/foo.png"></a>',
        );

        expect(tiptapEditor.getJSON()).toEqual(
          doc(
            p(
              image({
                src: 'http://localhost/foo.png',
                canonicalSrc: 'http://%{gitlab_server}/foo.png',
                alt: 'image',
              }),
            ),
          ).toJSON(),
        );
      });
    });

    describe('when the image has no data-placeholder attribute', () => {
      it('leaves the canonical src as is', () => {
        tiptapEditor.commands.setContent(
          '<img src="http://example.com/%25%7Bfoo%7D.png" alt="image" data-canonical-src="http://example.com/%25%7Bfoo%7D.png">',
        );

        expect(tiptapEditor.getJSON()).toEqual(
          doc(
            p(
              image({
                src: 'http://example.com/%25%7Bfoo%7D.png',
                canonicalSrc: 'http://example.com/%25%7Bfoo%7D.png',
                alt: 'image',
              }),
            ),
          ).toJSON(),
        );
      });
    });
  });
});
