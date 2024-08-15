import createMarkdownDeserializer from '~/content_editor/services/gl_api_markdown_deserializer';
import MarkdownSerializer from '~/content_editor/services/markdown_serializer';
import { builders, tiptapEditor, doc, text } from '../serialization_utils';

const { paragraph: p, bold, link, htmlComment } = builders;

jest.mock('~/emoji');

const source = (sourceMarkdown, sourceMapKey, sourceTagName) => ({
  sourceMarkdown,
  sourceMapKey,
  sourceTagName,
});

const MOCK_HTML = `<p data-sourcepos="1:1-1:22"><strong data-sourcepos="1:1-1:8">Bold</strong> and <a data-sourcepos="1:14-1:22" href="https://example.com">link</a></p>\n<!-- some comment -->`;
const MOCK_MARKDOWN = '**Bold** and [link][1]\n<!-- some comment -->\n\n[1]: https://example.com';

describe('content_editor/services/gl_api_markdown_deserializer', () => {
  let renderMarkdown;

  beforeEach(() => {
    renderMarkdown = jest.fn();
  });

  describe('when deserializing', () => {
    let deserializer;
    let result;

    beforeEach(() => {
      deserializer = createMarkdownDeserializer({ render: renderMarkdown });
    });

    describe('when preserveMarkdown feature is disabled', () => {
      beforeEach(async () => {
        gon.features = { preserveMarkdown: false };

        renderMarkdown.mockResolvedValueOnce({
          body: MOCK_HTML,
        });

        result = await deserializer.deserialize({
          markdown: MOCK_MARKDOWN,
          schema: tiptapEditor.schema,
        });
      });

      afterEach(() => {
        gon.features = {};
      });

      it('transforms HTML returned by render function to a ProseMirror document', () => {
        const document = doc(
          p(bold('Bold'), text(' and '), link({ href: 'https://example.com' }, 'link')),
          htmlComment({ description: 'some comment' }),
        );

        expect(result.document.content.toJSON()).toEqual(document.content.toJSON());
      });
    });

    describe('when preserveMarkdown feature is enabled', () => {
      beforeEach(async () => {
        gon.features = { preserveMarkdown: true };

        renderMarkdown.mockResolvedValueOnce({
          body: MOCK_HTML,
        });

        result = await deserializer.deserialize({
          markdown: MOCK_MARKDOWN,
          schema: tiptapEditor.schema,
        });
      });

      afterEach(() => {
        gon.features = {};
      });

      it('transforms HTML returned by render function to a ProseMirror document with sourcemaps', () => {
        const document = doc(
          p(
            source('**Bold** and [link][1]', '1:1-1:22', 'p'),
            bold(source('**Bold**', '1:1-1:8', 'strong'), 'Bold'),
            text(' and '),
            link({ ...source('[link][1]', '1:14-1:22', 'a'), href: 'https://example.com' }, 'link'),
          ),
          htmlComment({ description: 'some comment' }),
        );

        expect(result.document.content.toJSON()).toEqual(document.content.toJSON());
      });

      it('preserves reference style link definitions when serialized', () => {
        expect(
          new MarkdownSerializer().serialize({
            doc: result.document,
            pristineDoc: result.document,
          }),
        ).toBe('**Bold** and [link][1]\n\n<!--some comment-->\n\n[1]: https://example.com');
      });
    });
  });

  describe('when the render function returns an empty value', () => {
    it('returns an empty prosemirror document', async () => {
      const deserializer = createMarkdownDeserializer({
        render: renderMarkdown,
        schema: tiptapEditor.schema,
      });

      renderMarkdown.mockResolvedValueOnce({ body: null });

      const result = await deserializer.deserialize({
        markdown: '',
        schema: tiptapEditor.schema,
      });

      const document = doc(p());

      expect(result.document.content.toJSON()).toEqual(document.content.toJSON());
    });
  });
});
