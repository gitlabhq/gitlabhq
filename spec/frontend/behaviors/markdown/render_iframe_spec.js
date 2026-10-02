import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { iframeProviders, YOUTUBE_SANDBOX, FIGMA_SANDBOX } from 'helpers/iframe_providers';
import renderIframes from '~/behaviors/markdown/render_iframe';
import {
  YOUTUBE_EMBED_URL,
  fixtureDefault,
  fixtureWithDimensions,
  fixtureWithWidthOnly,
} from './mock_data';

describe('Embedded iframe renderer', () => {
  const findEmbeddedIframes = (src = null) => {
    const iframes = document.querySelectorAll('iframe');
    if (src === null) return iframes;

    return Array.from(iframes).filter((iframe) => iframe.src === src);
  };

  const renderAllIframes = () => {
    renderIframes([...document.querySelectorAll('.js-render-iframe')]);
    jest.runAllTimers();
  };

  beforeEach(() => {
    window.gon = {
      iframe_rendering_providers: iframeProviders(),
      features: {
        allowIframesInMarkdown: true,
      },
    };
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('renders an embedded iframe', () => {
    setHTMLFixture(fixtureDefault);

    expect(findEmbeddedIframes()).toHaveLength(0);

    renderAllIframes();

    expect(findEmbeddedIframes(YOUTUBE_EMBED_URL)).toHaveLength(1);
  });

  it("applies the provider's sandbox", () => {
    setHTMLFixture(fixtureDefault);

    renderAllIframes();

    expect(findEmbeddedIframes(YOUTUBE_EMBED_URL)[0].getAttribute('sandbox')).toBe(YOUTUBE_SANDBOX);
  });

  it("applies the matched provider's sandbox", () => {
    const figmaEmbedUrl = 'https://embed.figma.com/design/abc?embed-host=gitlab';
    setHTMLFixture(fixtureDefault);
    const img = document.querySelector('img');
    img.src = figmaEmbedUrl;
    img.dataset.iframeProviderId = 'figma';

    renderAllIframes();

    expect(findEmbeddedIframes(figmaEmbedUrl)[0].getAttribute('sandbox')).toBe(FIGMA_SANDBOX);
  });

  describe('when the provider is no longer enabled', () => {
    beforeEach(() => {
      setHTMLFixture(fixtureDefault);
      window.gon.iframe_rendering_providers = { figma: iframeProviders().figma };
    });

    it('does not render an embedded iframe and removes the image', () => {
      renderAllIframes();

      expect(findEmbeddedIframes()).toHaveLength(0);
      expect(document.querySelectorAll('img')).toHaveLength(0);
    });
  });

  describe("when the src origin does not match the provider's", () => {
    beforeEach(() => {
      setHTMLFixture(fixtureDefault);
      document.querySelector('img').dataset.iframeProviderId = 'figma';
    });

    it('does not render an embedded iframe and removes the image', () => {
      renderAllIframes();

      expect(findEmbeddedIframes()).toHaveLength(0);
      expect(document.querySelectorAll('img')).toHaveLength(0);
    });
  });

  it('does not render an embedded iframe when the feature flag is not enabled for the project or group', () => {
    setHTMLFixture(fixtureDefault);

    window.gon.features.allowIframesInMarkdown = false;

    renderAllIframes();

    expect(findEmbeddedIframes()).toHaveLength(0);
  });

  it('does not render an embedded iframe when the instance-wide setting is disabled', () => {
    setHTMLFixture(fixtureDefault);

    window.gon.iframe_rendering_providers = null;

    renderAllIframes();

    expect(findEmbeddedIframes()).toHaveLength(0);
  });

  it('does not render an embedded iframe on a page that pushes no feature flags', () => {
    setHTMLFixture(fixtureDefault);

    delete window.gon.features;

    expect(() => renderAllIframes()).not.toThrow();
    expect(findEmbeddedIframes()).toHaveLength(0);
  });

  describe('dimensions', () => {
    it('applies explicit width and height attributes when provided', () => {
      setHTMLFixture(fixtureWithDimensions);

      renderAllIframes();

      const iframe = findEmbeddedIframes(YOUTUBE_EMBED_URL)[0];
      expect(iframe).toBeDefined();
      expect(iframe.getAttribute('width')).toBe('560');
      expect(iframe.getAttribute('height')).toBe('315');
    });

    it('caps width to container with aspect-ratio when both dimensions are provided', () => {
      setHTMLFixture(fixtureWithDimensions);

      renderAllIframes();

      const iframe = findEmbeddedIframes(YOUTUBE_EMBED_URL)[0];
      expect(iframe.style.maxWidth).toBe('100%');
      expect(iframe.style.maxHeight).toBe('80vh');
      expect(iframe.style.aspectRatio).toBe('560 / 315');
      expect(iframe.style.height).toBe('auto');
    });

    it('caps width to container without aspect-ratio when only width is provided', () => {
      setHTMLFixture(fixtureWithWidthOnly);

      renderAllIframes();

      const iframe = findEmbeddedIframes(YOUTUBE_EMBED_URL)[0];
      expect(iframe.getAttribute('width')).toBe('560');
      expect(iframe.getAttribute('height')).toBeNull();
      expect(iframe.style.maxWidth).toBe('100%');
      expect(iframe.style.maxHeight).toBe('80vh');
      expect(iframe.style.aspectRatio).toBeUndefined();
      expect(iframe.style.height).toBe('');
    });

    it('does not add full-width/height styles when explicit dimensions are provided', () => {
      setHTMLFixture(fixtureWithDimensions);

      renderAllIframes();

      const iframe = findEmbeddedIframes(YOUTUBE_EMBED_URL)[0];
      expect(iframe.classList.contains('gl-w-full')).toBe(false);
      expect(iframe.classList.contains('gl-h-full')).toBe(false);
    });

    it('uses full-width/height when no dimensions are provided', () => {
      setHTMLFixture(fixtureDefault);

      renderAllIframes();

      const iframe = findEmbeddedIframes(YOUTUBE_EMBED_URL)[0];
      expect(iframe.classList.contains('gl-w-full')).toBe(true);
      expect(iframe.classList.contains('gl-h-full')).toBe(true);
      expect(iframe.style.maxHeight).toBe('80vh');
      expect(iframe.getAttribute('width')).toBeNull();
      expect(iframe.getAttribute('height')).toBeNull();
    });
  });
});
