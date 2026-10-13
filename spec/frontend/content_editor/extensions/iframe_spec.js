import { builders } from 'prosemirror-test-builder';
import { iframeProviders } from 'helpers/iframe_providers';
import { buildIframeEmbed, YOUTUBE_URL, YOUTUBE_EMBED_URL } from 'helpers/iframe_embeds';
import Iframe from '~/content_editor/extensions/iframe';
import Image from '~/content_editor/extensions/image';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/iframe', () => {
  let tiptapEditor;
  let doc;
  let p;
  let iframe;

  const setContent = (element) => tiptapEditor.commands.setContent(element.outerHTML);

  const parsedNodeTypes = (element) => {
    setContent(element);

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
    it('parses an embed container as an iframe node', () => {
      setContent(buildIframeEmbed({ title: 'YouTube video', width: '560', height: '315' }));

      const expected = doc(
        p(
          iframe({
            src: YOUTUBE_EMBED_URL,
            canonicalSrc: YOUTUBE_URL,
            providerId: 'youtube',
            alt: 'YouTube video',
            width: '560',
            height: '315',
          }),
        ),
      );

      expect(tiptapEditor.state.doc.toJSON()).toEqual(expected.toJSON());
    });

    it('keeps the provider when re-parsing its own rendered HTML', () => {
      setContent(buildIframeEmbed());
      tiptapEditor.commands.setContent(tiptapEditor.getHTML());

      expect(tiptapEditor.getJSON().content[0].content[0]).toMatchObject({
        type: 'iframe',
        attrs: { providerId: 'youtube' },
      });
    });

    it('does not parse a regular img as an iframe node', () => {
      const img = document.createElement('img');
      img.setAttribute('src', 'https://example.com/image.png');
      img.setAttribute('alt', 'image');

      expect(parsedNodeTypes(img)).toEqual(['image']);
    });

    it('does not parse a media container without the embed marker as an iframe node', () => {
      const embed = buildIframeEmbed();
      embed.classList.remove('js-render-iframe');

      expect(parsedNodeTypes(embed)).toEqual(['text']);
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
      ${"another provider's origin"}                  | ${'https://embed.figma.com/design/abc?embed-host=gitlab'}
    `('parses $description as the fallback link rather than an iframe node', ({ src }) => {
      expect(parsedNodeTypes(buildIframeEmbed({ src }))).toEqual(['text']);
    });
    /* eslint-enable no-script-url */

    it.each`
      description                       | providerId
      ${'an unknown provider'}          | ${'vimeo'}
      ${'no provider'}                  | ${''}
      ${'an Object.prototype property'} | ${'constructor'}
    `(
      'parses an allowed src attributed to $description as the fallback link rather than an iframe node',
      ({ providerId }) => {
        expect(parsedNodeTypes(buildIframeEmbed({ providerId }))).toEqual(['text']);
      },
    );

    it('does not parse an iframe node when iframe rendering is disabled', () => {
      window.gon.iframe_rendering_providers = null;

      expect(parsedNodeTypes(buildIframeEmbed())).toEqual(['text']);
    });

    it('does not parse an iframe node when the feature flag is disabled', () => {
      window.gon.features.allowIframesInMarkdown = false;

      expect(parsedNodeTypes(buildIframeEmbed())).toEqual(['text']);
    });
  });
});
