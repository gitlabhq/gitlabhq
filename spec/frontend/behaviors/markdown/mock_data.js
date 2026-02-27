// These fixtures represent the exact HTML output from the Banzai pipeline
// that the frontend iframe renderer receives and must transform.

export const YOUTUBE_EMBED_URL = 'https://www.youtube.com/embed/FIWD2qvNQHM';

const ASSET_PROXY_URL =
  'https://asset-proxy.example/fcba328ee7b6bfdfcc765f7dc8bef47249729c9b/68747470733a2f2f7777772e796f75747562652e636f6d2f656d6265642f464957443271764e51484d';

export const fixtureWithoutAssetProxy = `
  <p data-sourcepos="1:1-1:59" dir="auto">
    <span class="media-container img-container">
      <a class="gl-text-sm gl-text-subtle gl-mb-1"
         href="${YOUTUBE_EMBED_URL}"
         target="_blank" rel="nofollow noreferrer noopener" title="Download 'YouTube embed'">
        YouTube embed
      </a>
      <a class="no-attachment-icon"
         href="${YOUTUBE_EMBED_URL}"
         target="_blank" rel="nofollow noreferrer noopener">
        <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
             controls="true" data-setup="{}" data-title="YouTube embed" class="js-render-iframe lazy"
             decoding="async"
             data-src="${YOUTUBE_EMBED_URL}">
      </a>
    </span>
  </p>
`;

export const fixtureWithAssetProxy = `
  <p data-sourcepos="1:1-1:60" dir="auto">
    <span class="media-container img-container">
      <a class="gl-text-sm gl-text-subtle gl-mb-1"
         href="${ASSET_PROXY_URL}"
         target="_blank" rel="nofollow noreferrer noopener" title="Download 'YouTube iframe'"
         data-canonical-src="${YOUTUBE_EMBED_URL}">
        YouTube iframe
      </a>
      <a class="no-attachment-icon"
         href="${ASSET_PROXY_URL}"
         target="_blank" rel="nofollow noreferrer noopener"
         data-canonical-src="${YOUTUBE_EMBED_URL}">
        <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
             controls="true" data-setup="{}" data-title="YouTube iframe" class="js-render-iframe lazy"
             data-canonical-src="${YOUTUBE_EMBED_URL}"
             decoding="async"
             data-src="${ASSET_PROXY_URL}">
      </a>
    </span>
  </p>
`;

export const fixtureWithDimensions = `
  <p data-sourcepos="1:1-1:59" dir="auto">
    <span class="media-container img-container">
      <a class="gl-text-sm gl-text-subtle gl-mb-1"
         href="${YOUTUBE_EMBED_URL}"
         target="_blank" rel="nofollow noreferrer noopener" title="Download 'YouTube embed'">
        YouTube embed
      </a>
      <a class="no-attachment-icon"
         href="${YOUTUBE_EMBED_URL}"
         target="_blank" rel="nofollow noreferrer noopener">
        <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
             controls="true" data-setup="{}" data-title="YouTube embed" class="js-render-iframe lazy"
             decoding="async"
             data-src="${YOUTUBE_EMBED_URL}"
             width="560" height="315">
      </a>
    </span>
  </p>
`;

export const fixtureWithWidthOnly = `
  <p data-sourcepos="1:1-1:59" dir="auto">
    <span class="media-container img-container">
      <a class="gl-text-sm gl-text-subtle gl-mb-1"
         href="${YOUTUBE_EMBED_URL}"
         target="_blank" rel="nofollow noreferrer noopener" title="Download 'YouTube embed'">
        YouTube embed
      </a>
      <a class="no-attachment-icon"
         href="${YOUTUBE_EMBED_URL}"
         target="_blank" rel="nofollow noreferrer noopener">
        <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
             controls="true" data-setup="{}" data-title="YouTube embed" class="js-render-iframe lazy"
             decoding="async"
             data-src="${YOUTUBE_EMBED_URL}"
             width="560">
      </a>
    </span>
  </p>
`;
