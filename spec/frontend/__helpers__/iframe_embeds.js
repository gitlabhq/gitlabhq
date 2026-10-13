export const YOUTUBE_URL = 'https://www.youtube.com/watch?v=FIWD2qvNQHM';
export const YOUTUBE_EMBED_URL = 'https://www.youtube.com/embed/FIWD2qvNQHM';

export const buildIframeEmbed = ({
  src = YOUTUBE_EMBED_URL,
  canonicalSrc = YOUTUBE_URL,
  providerId = 'youtube',
  title = 'YouTube embed',
  width = null,
  height = null,
} = {}) => {
  const container = document.createElement('span');
  container.classList.add('media-container', 'iframe-container', 'js-render-iframe');
  container.dataset.iframeSrc = src;
  container.dataset.iframeCanonicalSrc = canonicalSrc;
  container.dataset.iframeProviderId = providerId;
  if (title) container.dataset.title = title;
  if (width) container.dataset.width = width;
  if (height) container.dataset.height = height;

  const link = document.createElement('a');
  link.href = canonicalSrc;
  link.rel = 'nofollow noreferrer noopener';
  link.target = '_blank';
  link.textContent = title || canonicalSrc;
  container.append(link);

  return container;
};

export const buildParagraphWithIframeEmbed = (options) => {
  const paragraph = document.createElement('p');
  paragraph.dir = 'auto';
  paragraph.append(buildIframeEmbed(options));

  return paragraph;
};
