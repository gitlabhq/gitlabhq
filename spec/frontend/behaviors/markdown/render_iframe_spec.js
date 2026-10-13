import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { iframeProviders, YOUTUBE_SANDBOX, FIGMA_SANDBOX } from 'helpers/iframe_providers';
import renderIframes from '~/behaviors/markdown/render_iframe';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import {
  YOUTUBE_URL,
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

  const findWarning = () => document.querySelector('[data-testid="external-content-warning"]');
  const findOpenInNewTab = () =>
    document.querySelector('[data-testid="external-content-open-in-new-tab"]');
  const findActivationButton = () =>
    document.querySelector('[data-testid="activate-external-content"]');
  const findPlaceholder = () =>
    document.querySelector('[data-testid="external-content-placeholder"]');

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

  it("applies the matched provider's sandbox", async () => {
    const figmaEmbedUrl = 'https://embed.figma.com/design/abc?embed-host=gitlab';
    setHTMLFixture(fixtureDefault);
    const img = document.querySelector('img');
    img.src = figmaEmbedUrl;
    img.dataset.iframeProviderId = 'figma';

    renderAllIframes();
    findActivationButton().click();
    await nextTick();

    expect(findEmbeddedIframes(figmaEmbedUrl)[0].getAttribute('sandbox')).toBe(FIGMA_SANDBOX);
  });

  it('warns that the content is external', () => {
    setHTMLFixture(fixtureDefault);

    renderAllIframes();

    expect(findWarning().textContent).toContain(
      'You are viewing external content from www.youtube.com. GitLab does not control this content.',
    );
  });

  it('links to the canonical source in a new tab', () => {
    setHTMLFixture(fixtureDefault);

    renderAllIframes();

    expect(findOpenInNewTab().getAttribute('href')).toBe(YOUTUBE_URL);
  });

  it('keeps the original image hidden alongside the embed', () => {
    setHTMLFixture(fixtureDefault);
    const img = document.querySelector('img');

    renderAllIframes();

    expect(img.hidden).toBe(true);
    expect(img.parentElement.classList.contains('media-container')).toBe(true);
  });

  it('removes the link wrapping the original image', () => {
    setHTMLFixture(fixtureDefault);
    const link = document.querySelector('a');

    renderAllIframes();

    expect(link.isConnected).toBe(false);
  });

  describe('when the rendered embed is copied', () => {
    const copySelection = () => {
      const fragment = document.createDocumentFragment();
      fragment.appendChild(document.querySelector('p').cloneNode(true));
      return CopyAsGFM.transformGFMSelection(fragment);
    };

    beforeEach(() => {
      setHTMLFixture(fixtureDefault);
      renderAllIframes();
    });

    it('copies no plain text', () => {
      expect(copySelection().textContent.trim()).toBe('');
    });

    it('copies the embed as GFM', async () => {
      expect(await CopyAsGFM.nodeToGFM(copySelection())).toBe(
        `![YouTube embed](${YOUTUBE_EMBED_URL})`,
      );
    });
  });

  it('names the frame after the provider and host', () => {
    setHTMLFixture(fixtureDefault);

    renderAllIframes();

    expect(findEmbeddedIframes(YOUTUBE_EMBED_URL)[0].getAttribute('title')).toBe(
      'External content from YouTube (www.youtube.com)',
    );
  });

  describe('when the provider requires activation', () => {
    beforeEach(() => {
      setHTMLFixture(fixtureDefault);
      window.gon.iframe_rendering_providers.youtube.require_activation = true;
      renderAllIframes();
    });

    it('does not load the iframe', () => {
      expect(findEmbeddedIframes()).toHaveLength(0);
    });

    it('does not warn yet', () => {
      expect(findWarning()).toBeNull();
    });

    it('shows an activation button', () => {
      expect(findActivationButton().textContent.trim()).toBe('Load external content');
    });

    it('sizes the placeholder like the default iframe', () => {
      expect(findPlaceholder().style.width).toBe('560px');
    });

    describe('when the user activates the content', () => {
      beforeEach(async () => {
        findActivationButton().click();
        await waitForPromises();
      });

      it('loads the iframe', () => {
        expect(findEmbeddedIframes(YOUTUBE_EMBED_URL)).toHaveLength(1);
      });

      it('moves focus to the iframe', () => {
        expect(document.activeElement).toBe(findEmbeddedIframes(YOUTUBE_EMBED_URL)[0]);
      });

      it('removes the activation button', () => {
        expect(findActivationButton()).toBeNull();
      });

      it('warns that the content is external', () => {
        expect(findWarning()).not.toBeNull();
      });
    });
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
    const findIframe = () => findEmbeddedIframes(YOUTUBE_EMBED_URL)[0];

    describe('for any embed', () => {
      beforeEach(() => {
        setHTMLFixture(fixtureDefault);
        renderAllIframes();
      });

      it('keeps the embed within its container, with a floor that yields to it', () => {
        const { style } = findIframe().parentElement;
        expect(style.maxWidth).toBe('100%');
        expect(style.minWidth).toBe('min(17rem, 100%)');
      });

      it('fills the embed with the iframe', () => {
        expect(findIframe().classList.contains('gl-min-w-full')).toBe(true);
      });
    });

    describe('when both width and height are provided', () => {
      beforeEach(() => {
        setHTMLFixture(fixtureWithDimensions);
        renderAllIframes();
      });

      it('applies explicit width and height attributes', () => {
        const iframe = findIframe();
        expect(iframe).toBeDefined();
        expect(iframe.getAttribute('width')).toBe('560');
        expect(iframe.getAttribute('height')).toBe('315');
      });

      it('caps width to container and height to the requested height', () => {
        const iframe = findIframe();
        expect(iframe.style.maxWidth).toBe('100%');
        expect(iframe.style.maxHeight).toBe('min(80vh, 315px)');
        expect(iframe.style.height).toBe('auto');
      });
    });

    describe('when only width is provided', () => {
      beforeEach(() => {
        setHTMLFixture(fixtureWithWidthOnly);
        renderAllIframes();
      });

      it('caps width to container without aspect-ratio', () => {
        const iframe = findIframe();
        expect(iframe.getAttribute('width')).toBe('560');
        expect(iframe.getAttribute('height')).toBeNull();
        expect(iframe.style.maxWidth).toBe('100%');
        expect(iframe.style.maxHeight).toBe('80vh');
        expect(iframe.style.height).toBe('');
      });
    });

    describe('when no dimensions are provided', () => {
      beforeEach(() => {
        setHTMLFixture(fixtureDefault);
        renderAllIframes();
      });

      it('defaults to 560 by 315', () => {
        const iframe = findIframe();
        expect(iframe.getAttribute('width')).toBe('560');
        expect(iframe.getAttribute('height')).toBe('315');
        expect(iframe.style.maxHeight).toBe('min(80vh, 315px)');
        expect(iframe.style.height).toBe('auto');
      });
    });
  });
});
