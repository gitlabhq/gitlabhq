import createMarkdownDeserializer, {
  transformQuickActions,
} from '~/content_editor/services/gl_api_markdown_deserializer';
import MarkdownSerializer from '~/content_editor/services/markdown_serializer';
import { builders, tiptapEditor, doc, text } from '../serialization_utils';
import {
  REPOSITORY_RELATIVE_IMAGE_HTML,
  REPOSITORY_RELATIVE_IMAGE_WITHOUT_CANONICAL_SRC_HTML,
  REPOSITORY_RELATIVE_LINK_HTML,
  REPOSITORY_RELATIVE_LINK_WITH_TITLE_HTML,
  REPOSITORY_RELATIVE_LINKED_IMAGE_HTML,
  REPOSITORY_RELATIVE_IMAGE_IN_LIST_HTML,
  REPOSITORY_RELATIVE_IMAGE_IN_TABLE_HTML,
  REPOSITORY_RELATIVE_IMAGE_WITH_TITLE_HTML,
  REPOSITORY_RELATIVE_MIXED_PARAGRAPH_HTML,
  UPLOAD_IMAGE_HTML,
  ASSET_PROXIED_IMAGE_HTML,
  RESOLVED_REFERENCES_PARAGRAPH_HTML,
  LINK_REFERENCE_HTML,
} from '../test_constants';

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

  describe('round trip of HTML rendered by the backend', () => {
    const roundTrip = async (html, markdown) => {
      const deserializer = createMarkdownDeserializer({ render: renderMarkdown });
      renderMarkdown.mockResolvedValueOnce({ body: html });

      const { document } = await deserializer.deserialize({
        markdown,
        schema: tiptapEditor.schema,
      });

      return new MarkdownSerializer().serialize({ doc: document });
    };

    it.each`
      description                                                  | html                                        | markdown
      ${'an image from the repository'}                            | ${REPOSITORY_RELATIVE_IMAGE_HTML}           | ${'![logo](app/assets/images/logo.svg)'}
      ${'a link to a file in the repository'}                      | ${REPOSITORY_RELATIVE_LINK_HTML}            | ${'[readme](README.md)'}
      ${'a titled link to a file in the repository'}               | ${REPOSITORY_RELATIVE_LINK_WITH_TITLE_HTML} | ${'[readme](README.md "the *title*")'}
      ${'a linked image from the repository'}                      | ${REPOSITORY_RELATIVE_LINKED_IMAGE_HTML}    | ${'[![logo](app/assets/images/logo.svg)](https://gitlab.com)'}
      ${'repository images in a nested list'}                      | ${REPOSITORY_RELATIVE_IMAGE_IN_LIST_HTML}   | ${'* item one\n* item with ![logo](app/assets/images/logo.svg) inline\n  * nested ![logo](app/assets/images/logo.svg)'}
      ${'a paragraph mixing a repository link and image'}          | ${REPOSITORY_RELATIVE_MIXED_PARAGRAPH_HTML} | ${'Read [the readme](README.md) and ![logo](app/assets/images/logo.svg) here'}
      ${'an uploaded image'}                                       | ${UPLOAD_IMAGE_HTML}                        | ${'![up](/uploads/0123456789abcdef0123456789abcdef/x.png)'}
      ${'an image from another host'}                              | ${ASSET_PROXIED_IMAGE_HTML}                 | ${'![abs](https://example.com/a.png)'}
      ${'issue, merge request, user, label and commit references'} | ${RESOLVED_REFERENCES_PARAGRAPH_HTML}       | ${'See #1 and !1 by @root with ~bug in b51c8ef20575'}
      ${'a link whose target is an issue URL'}                     | ${LINK_REFERENCE_HTML}                      | ${'[the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/1)'}
    `('serializes $description back to the same markdown', async ({ html, markdown }) => {
      expect(await roundTrip(html, markdown)).toBe(markdown);
    });

    it('serializes a repository image in a table cell back to a pipe table', async () => {
      const markdown = '| a | b |\n|---|---|\n| ![logo](app/assets/images/logo.svg) | text |';

      expect(await roundTrip(REPOSITORY_RELATIVE_IMAGE_IN_TABLE_HTML, markdown)).toBe(
        '| a | b |\n|---|---|\n| ![logo](app/assets/images/logo.svg) | text |\n\n',
      );
    });

    it('normalizes the alt text of a repository image the way the backend renders it', async () => {
      const markdown = '![alt *with* `md` [chars]](app/assets/images/logo.svg "the *title*")';

      expect(await roundTrip(REPOSITORY_RELATIVE_IMAGE_WITH_TITLE_HTML, markdown)).toBe(
        '![alt with md [chars]](app/assets/images/logo.svg "the *title*")',
      );
    });

    it('falls back to the resolved path when the backend sends no data-canonical-src', async () => {
      const markdown = '![logo](app/assets/images/logo.svg)';

      expect(await roundTrip(REPOSITORY_RELATIVE_IMAGE_WITHOUT_CANONICAL_SRC_HTML, markdown)).toBe(
        '![logo](/gitlab-org/gitlab/-/raw/master/app/assets/images/logo.svg)',
      );
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
