export function appendWidthToAvatarUrl(url, width) {
  const DATA_URI_PREFIX = 'data:';
  const WIDTH_PARAM = 'width=';

  if (!url || url.startsWith(DATA_URI_PREFIX) || url.includes(WIDTH_PARAM)) {
    return url;
  }

  return url.includes('?') ? `${url}&width=${width}` : `${url}?width=${width}`;
}
