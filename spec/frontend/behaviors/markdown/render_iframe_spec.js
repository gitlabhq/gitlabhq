import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import renderIframes from '~/behaviors/markdown/render_iframe';

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

  const target = 'https://www.youtube.com/embed/FIWD2qvNQHM';

  // The fixtures are exactly what we get handed by the backend and need to transform.
  const fixtureWithoutAssetProxy = `
    <p data-sourcepos="1:1-1:59" dir="auto">
      <span class="media-container img-container">
        <a class="gl-text-sm gl-text-subtle gl-mb-1"
           href="https://www.youtube.com/embed/FIWD2qvNQHM"
           target="_blank" rel="nofollow noreferrer noopener" title="Download 'YouTube embed'">
          YouTube embed
        </a>
        <a class="no-attachment-icon"
           href="https://www.youtube.com/embed/FIWD2qvNQHM"
           target="_blank" rel="nofollow noreferrer noopener">
          <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
               controls="true" data-setup="{}" data-title="YouTube embed" class="js-render-iframe lazy"
               decoding="async"
               data-src="https://www.youtube.com/embed/FIWD2qvNQHM">
        </a>
      </span>
    </p>
  `;

  const fixtureWithAssetProxy = `
    <p data-sourcepos="1:1-1:60" dir="auto">
      <span class="media-container img-container">
        <a class="gl-text-sm gl-text-subtle gl-mb-1"
           href="https://asset-proxy.example/fcba328ee7b6bfdfcc765f7dc8bef47249729c9b/68747470733a2f2f7777772e796f75747562652e636f6d2f656d6265642f464957443271764e51484d"
           target="_blank" rel="nofollow noreferrer noopener" title="Download 'YouTube iframe'"
           data-canonical-src="https://www.youtube.com/embed/FIWD2qvNQHM">
          YouTube iframe
        </a>
        <a class="no-attachment-icon"
           href="https://asset-proxy.example/fcba328ee7b6bfdfcc765f7dc8bef47249729c9b/68747470733a2f2f7777772e796f75747562652e636f6d2f656d6265642f464957443271764e51484d"
           target="_blank" rel="nofollow noreferrer noopener"
           data-canonical-src="https://www.youtube.com/embed/FIWD2qvNQHM">
          <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
               controls="true" data-setup="{}" data-title="YouTube iframe" class="js-render-iframe lazy"
               data-canonical-src="https://www.youtube.com/embed/FIWD2qvNQHM"
               decoding="async"
               data-src="https://asset-proxy.example/fcba328ee7b6bfdfcc765f7dc8bef47249729c9b/68747470733a2f2f7777772e796f75747562652e636f6d2f656d6265642f464957443271764e51484d">
        </a>
      </span>
    </p>
  `;

  it('renders an embedded iframe when the asset proxy is disabled', () => {
    setHTMLFixture(fixtureWithoutAssetProxy);

    expect(findEmbeddedIframes()).toHaveLength(0);

    renderAllIframes();

    expect(findEmbeddedIframes(target)).toHaveLength(1);
  });

  it('renders an embedded iframe when the asset proxy is enabled', () => {
    setHTMLFixture(fixtureWithAssetProxy);

    expect(findEmbeddedIframes()).toHaveLength(0);

    renderAllIframes();

    expect(findEmbeddedIframes(target)).toHaveLength(1);
  });

  it('does not render an embedded iframe when the allowlist has no match', () => {
    setHTMLFixture(fixtureWithAssetProxy);

    // No YouTube.
    window.gon.iframe_rendering_allowlist = ['embed.figma.com'];

    renderAllIframes();

    expect(findEmbeddedIframes()).toHaveLength(0);
  });

  it('does not render an embedded iframe when the feature flag is not enabled for the project or group', () => {
    setHTMLFixture(fixtureWithAssetProxy);

    window.gon.features.allowIframesInMarkdown = false;

    renderAllIframes();

    expect(findEmbeddedIframes()).toHaveLength(0);
  });

  it('does not render an embedded iframe when the instance-wide setting is disabled', () => {
    setHTMLFixture(fixtureWithAssetProxy);

    window.gon.iframe_rendering_enabled = false;

    renderAllIframes();

    expect(findEmbeddedIframes()).toHaveLength(0);
  });
});
