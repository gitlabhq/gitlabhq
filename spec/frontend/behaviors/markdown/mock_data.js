// These fixtures represent the exact HTML output from the Banzai pipeline
// that the frontend iframe renderer receives and must transform.

export const YOUTUBE_URL = 'https://www.youtube.com/watch?v=FIWD2qvNQHM';
export const YOUTUBE_EMBED_URL = 'https://www.youtube.com/embed/FIWD2qvNQHM';

export const fixtureDefault = `
  <p data-sourcepos="1:1-1:61" dir="auto">
    <span class="media-container img-container">
      <a class="no-attachment-icon" href="${YOUTUBE_EMBED_URL}" target="_blank" rel="nofollow noreferrer noopener">
        <img src="${YOUTUBE_EMBED_URL}"
             controls="true" data-setup="{}" data-title="YouTube embed"
             data-iframe-canonical-src="${YOUTUBE_URL}"
             data-iframe-provider-id="youtube"
             class="js-render-iframe">
      </a>
    </span>
  </p>
`;

export const fixtureWithDimensions = `
  <p data-sourcepos="1:1-1:83" dir="auto">
    <span class="media-container img-container">
      <a class="no-attachment-icon" href="${YOUTUBE_EMBED_URL}" target="_blank" rel="nofollow noreferrer noopener">
        <img src="${YOUTUBE_EMBED_URL}"
             controls="true" data-setup="{}" data-title="YouTube embed"
             data-iframe-canonical-src="${YOUTUBE_URL}"
             data-iframe-provider-id="youtube"
             class="js-render-iframe"
             height="315" width="560">
      </a>
    </span>
  </p>
`;

export const fixtureWithWidthOnly = `
  <p data-sourcepos="1:1-1:72" dir="auto">
    <span class="media-container img-container">
      <a class="no-attachment-icon" href="${YOUTUBE_EMBED_URL}" target="_blank" rel="nofollow noreferrer noopener">
        <img src="${YOUTUBE_EMBED_URL}"
             controls="true" data-setup="{}" data-title="YouTube embed"
             data-iframe-canonical-src="${YOUTUBE_URL}"
             data-iframe-provider-id="youtube"
             class="js-render-iframe"
             width="560">
      </a>
    </span>
  </p>
`;
