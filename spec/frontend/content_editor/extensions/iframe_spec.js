import { builders } from 'prosemirror-test-builder';
import { iframeProviders } from 'helpers/iframe_providers';
import Iframe from '~/content_editor/extensions/iframe';
import Image from '~/content_editor/extensions/image';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/iframe', () => {
  let tiptapEditor;
  let doc;
  let p;
  let iframe;

  const mediaContainer = (src, providerId = 'youtube') =>
    `<span class="media-container img-container"><img class="js-render-iframe" src="${src}" data-iframe-provider-id="${providerId}"></span>`;

  const parsedNodeTypes = (html) => {
    tiptapEditor.commands.setContent(html);

    return tiptapEditor.getJSON().content[0].content.map((node) => node.type);
  };

  beforeEach(() => {
    window.gon = {
      iframe_rendering_providers: iframeProviders(),
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
          'data-iframe-provider-id="youtube" ' +
          'data-title="YouTube video" width="560" height="315">' +
          '</span>',
      );

      const expected = doc(
        p(
          iframe({
            src: 'https://www.youtube.com/embed/abc123',
            canonicalSrc: 'https://www.youtube.com/watch?v=abc123',
            providerId: 'youtube',
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
        mediaContainer('https://embed.figma.com/design/abc', 'figma'),
      );

      const expected = doc(
        p(
          iframe({
            src: 'https://embed.figma.com/design/abc',
            canonicalSrc: 'https://embed.figma.com/design/abc',
            providerId: 'figma',
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
      ${'a host belonging to no provider'}            | ${'https://evil.example.com/embed/abc'}
      ${'a relative path'}                            | ${'/uploads/abc'}
      ${'an unparseable URL'}                         | ${'http://['}
      ${"a host suffixed onto the provider's domain"} | ${'https://www.youtube.com.evil.example/embed/abc'}
      ${"the provider's domain in the query string"}  | ${'https://evil.example.com/embed?u=www.youtube.com'}
      ${"the provider's domain in the userinfo"}      | ${'https://www.youtube.com@evil.example.com/embed'}
      ${"another provider's origin"}                  | ${'https://embed.figma.com/design/abc'}
    `('parses $description as an image node rather than an iframe node', ({ src }) => {
      const nodeTypes = parsedNodeTypes(mediaContainer(src));

      expect(nodeTypes).not.toContain('iframe');
      expect(nodeTypes).toContain('image');
    });
    /* eslint-enable no-script-url */

    it.each`
      description                       | providerId
      ${'an unknown provider'}          | ${'vimeo'}
      ${'no provider'}                  | ${''}
      ${'an Object.prototype property'} | ${'constructor'}
    `(
      'parses an allowed src attributed to $description as an image node rather than an iframe node',
      ({ providerId }) => {
        const nodeTypes = parsedNodeTypes(
          mediaContainer('https://www.youtube.com/embed/abc123', providerId),
        );

        expect(nodeTypes).not.toContain('iframe');
        expect(nodeTypes).toContain('image');
      },
    );

    it("parses a disallowed src with the provider's canonical src as an image node", () => {
      const nodeTypes = parsedNodeTypes(
        '<span class="media-container img-container">' +
          '<img class="js-render-iframe" src="javascript:alert(document.domain)" ' +
          'data-iframe-canonical-src="https://www.youtube.com/watch?v=abc" ' +
          'data-iframe-provider-id="youtube">' +
          '</span>',
      );

      expect(nodeTypes).not.toContain('iframe');
      expect(nodeTypes).toContain('image');
    });

    it('does not parse an iframe node when iframe rendering is disabled', () => {
      window.gon.iframe_rendering_providers = null;

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
