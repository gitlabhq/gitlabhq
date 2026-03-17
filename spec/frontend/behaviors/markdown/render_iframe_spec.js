import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
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
      iframe_rendering_enabled: true,
      iframe_rendering_allowlist: ['www.youtube.com'],
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

  it('does not render an embedded iframe and removes the image when the allowlist has no match', () => {
    setHTMLFixture(fixtureDefault);

    window.gon.iframe_rendering_allowlist = ['embed.figma.com'];

    renderAllIframes();

    expect(findEmbeddedIframes()).toHaveLength(0);
    expect(document.querySelectorAll('img')).toHaveLength(0);
  });

  it('does not render an embedded iframe when the feature flag is not enabled for the project or group', () => {
    setHTMLFixture(fixtureDefault);

    window.gon.features.allowIframesInMarkdown = false;

    renderAllIframes();

    expect(findEmbeddedIframes()).toHaveLength(0);
  });

  it('does not render an embedded iframe when the instance-wide setting is disabled', () => {
    setHTMLFixture(fixtureDefault);

    window.gon.iframe_rendering_enabled = false;

    renderAllIframes();

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
      expect(iframe.getAttribute('width')).toBeNull();
      expect(iframe.getAttribute('height')).toBeNull();
    });
  });
});
