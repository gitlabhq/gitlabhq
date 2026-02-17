import createMarkdownDeserializer, {
  transformQuickActions,
} from '~/content_editor/services/gl_api_markdown_deserializer';
import { builders, tiptapEditor, doc, text } from '../serialization_utils';

const { paragraph: p, bold, link, htmlComment } = builders;

jest.mock('~/emoji');

const MOCK_HTML = `<p data-sourcepos="1:1-1:22"><strong data-sourcepos="1:1-1:8">Bold</strong> and <a data-sourcepos="1:14-1:22" href="https://example.com">link</a></p>\n<!-- some comment -->`;
const MOCK_MARKDOWN = '**Bold** and [link][1]\n<!-- some comment -->\n\n[1]: https://example.com';

describe('content_editor/services/gl_api_markdown_deserializer', () => {
  let renderMarkdown;

  beforeEach(() => {
    renderMarkdown = jest.fn();
  });

  describe('transformQuickActions', () => {
    it('ensures at least 3 newlines after quick actions so that reference style links after the quick action are correctly parsed', () => {
      expect(
        transformQuickActions('Link to [GitLab][link]\n/confidential\n[link]: https://gitlab.com'),
      ).toBe('Link to [GitLab][link]\n/confidential\n\n\n[link]: https://gitlab.com');
    });
  });

  describe('when deserializing', () => {
    let deserializer;
    let result;

    beforeEach(async () => {
      deserializer = createMarkdownDeserializer({ render: renderMarkdown });

      renderMarkdown.mockResolvedValueOnce({
        body: MOCK_HTML,
      });

      result = await deserializer.deserialize({
        markdown: MOCK_MARKDOWN,
        schema: tiptapEditor.schema,
      });
    });

    it('transforms HTML returned by render function to a ProseMirror document', () => {
      const document = doc(
        p(bold('Bold'), text(' and '), link({ href: 'https://example.com' }, 'link')),
        htmlComment({ description: 'some comment' }),
      );

      expect(result.document.content.toJSON()).toEqual(document.content.toJSON());
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
