import { builders } from 'prosemirror-test-builder';
import Iframe from '~/content_editor/extensions/iframe';
import Image from '~/content_editor/extensions/image';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/iframe', () => {
  let tiptapEditor;
  let doc;
  let p;
  let iframe;

  const mediaContainer = (src) =>
    `<span class="media-container img-container"><img class="js-render-iframe" src="${src}"></span>`;

  const parsedNodeTypes = (html) => {
    tiptapEditor.commands.setContent(html);

    return tiptapEditor.getJSON().content[0].content.map((node) => node.type);
  };

  beforeEach(() => {
    window.gon = {
      iframe_rendering_enabled: true,
      iframe_rendering_allowlist: ['www.youtube.com', 'embed.figma.com'],
      features: { allowIframesInMarkdown: true },
    };

    tiptapEditor = createTestEditor({ extensions: [Image, Iframe] });

    ({ doc, paragraph: p, iframe } = builders(tiptapEditor.schema));
  });

  it('sets the draggable option to true', () => {
    expect(Iframe.config.draggable).toBe(true);
  });

  describe('parsing HTML', () => {
    it('parses an img with js-render-iframe class inside a media-container as an iframe node', () => {
      tiptapEditor.commands.setContent(
        '<span class="media-container img-container">' +
          '<img class="js-render-iframe" src="https://www.youtube.com/embed/abc123" ' +
          'data-iframe-canonical-src="https://www.youtube.com/watch?v=abc123" ' +
          'data-title="YouTube video" width="560" height="315">' +
          '</span>',
      );

      const expected = doc(
        p(
          iframe({
            src: 'https://www.youtube.com/embed/abc123',
            canonicalSrc: 'https://www.youtube.com/watch?v=abc123',
            alt: 'YouTube video',
            width: '560',
            height: '315',
          }),
        ),
      );

      expect(tiptapEditor.state.doc.toJSON()).toEqual(expected.toJSON());
    });

    it('falls back to src when data-iframe-canonical-src is not present', () => {
      tiptapEditor.commands.setContent(
        '<span class="media-container img-container">' +
          '<img class="js-render-iframe" src="https://embed.figma.com/design/abc">' +
          '</span>',
      );

      const expected = doc(
        p(
          iframe({
            src: 'https://embed.figma.com/design/abc',
            canonicalSrc: 'https://embed.figma.com/design/abc',
          }),
        ),
      );

      expect(tiptapEditor.state.doc.toJSON()).toEqual(expected.toJSON());
    });

    it('does not parse a regular img as an iframe node', () => {
      tiptapEditor.commands.setContent('<img src="https://example.com/image.png" alt="image">');

      const json = tiptapEditor.getJSON();
      const nodeTypes = json.content[0].content.map((n) => n.type);

      expect(nodeTypes).not.toContain('iframe');
      expect(nodeTypes).toContain('image');
    });

    it('does not parse an img without js-render-iframe class in a media-container', () => {
      tiptapEditor.commands.setContent(
        '<span class="media-container img-container">' +
          '<img src="https://example.com/image.png" alt="image">' +
          '</span>',
      );

      const json = tiptapEditor.getJSON();
      const nodeTypes = json.content[0].content.map((n) => n.type);

      expect(nodeTypes).not.toContain('iframe');
    });
  });

  describe('#security: parsing HTML with a disallowed src', () => {
    /* eslint-disable no-script-url */
    it.each`
      description                                     | src
      ${'a javascript: URL'}                          | ${'javascript:alert(document.domain)'}
      ${'a data: URL'}                                | ${'data:text/html,<script>alert(1)</script>'}
      ${'a non-allowlisted host'}                     | ${'https://evil.example.com/embed/abc'}
      ${'a relative path'}                            | ${'/uploads/abc'}
      ${'an unparseable URL'}                         | ${'http://['}
      ${'a host suffixed onto an allowlisted domain'} | ${'https://www.youtube.com.evil.example/embed/abc'}
      ${'an allowlisted domain in the query string'}  | ${'https://evil.example.com/embed?u=www.youtube.com'}
      ${'an allowlisted domain in the userinfo'}      | ${'https://www.youtube.com@evil.example.com/embed'}
    `('parses $description as an image node rather than an iframe node', ({ src }) => {
      const nodeTypes = parsedNodeTypes(mediaContainer(src));

      expect(nodeTypes).not.toContain('iframe');
      expect(nodeTypes).toContain('image');
    });
    /* eslint-enable no-script-url */

    it('parses a disallowed src with an allowlisted canonical src as an image node', () => {
      const nodeTypes = parsedNodeTypes(
        '<span class="media-container img-container">' +
          '<img class="js-render-iframe" src="javascript:alert(document.domain)" ' +
          'data-iframe-canonical-src="https://www.youtube.com/watch?v=abc">' +
          '</span>',
      );

      expect(nodeTypes).not.toContain('iframe');
      expect(nodeTypes).toContain('image');
    });

    it('does not parse an iframe node when iframe rendering is disabled', () => {
      window.gon.iframe_rendering_enabled = false;

      const nodeTypes = parsedNodeTypes(mediaContainer('https://www.youtube.com/embed/abc123'));

      expect(nodeTypes).not.toContain('iframe');
      expect(nodeTypes).toContain('image');
    });

    it('does not parse an iframe node when the feature flag is disabled', () => {
      window.gon.features.allowIframesInMarkdown = false;

      const nodeTypes = parsedNodeTypes(mediaContainer('https://www.youtube.com/embed/abc123'));

      expect(nodeTypes).not.toContain('iframe');
      expect(nodeTypes).toContain('image');
    });
  });
});
