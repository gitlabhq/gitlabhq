// These fixtures represent the exact HTML output from the Banzai pipeline
// that the frontend iframe renderer receives and must transform.

export const YOUTUBE_EMBED_URL = 'https://www.youtube.com/embed/FIWD2qvNQHM';

export const fixtureDefault = `
  <p data-sourcepos="1:1-1:59" dir="auto">
    <span class="media-container img-container">
      <img src="${YOUTUBE_EMBED_URL}"
           controls="true" data-setup="{}" data-title="YouTube embed"
           class="js-render-iframe">
    </span>
  </p>
`;

export const fixtureWithDimensions = `
  <p data-sourcepos="1:1-1:59" dir="auto">
    <span class="media-container img-container">
      <img src="${YOUTUBE_EMBED_URL}"
           controls="true" data-setup="{}" data-title="YouTube embed"
           class="js-render-iframe"
           width="560" height="315">
    </span>
  </p>
`;

export const fixtureWithWidthOnly = `
  <p data-sourcepos="1:1-1:59" dir="auto">
    <span class="media-container img-container">
      <img src="${YOUTUBE_EMBED_URL}"
           controls="true" data-setup="{}" data-title="YouTube embed"
           class="js-render-iframe"
           width="560">
    </span>
  </p>
`;
