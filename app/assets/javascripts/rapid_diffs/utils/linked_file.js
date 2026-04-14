const fileHashRegex = /[\da-f]{40}/;

export const removeLinkedFileUrlParams = (originalUrl) => {
  const url = new URL(originalUrl, window.location);
  url.searchParams.delete('file_path');
  url.searchParams.delete('old_path');
  url.searchParams.delete('new_path');
  if (
    url.hash.startsWith('#line_') ||
    url.hash.startsWith('#note_') ||
    fileHashRegex.test(url.hash.substring(1))
  )
    url.hash = '';
  return url;
};

export const withLinkedFileUrlParams = (originalUrl, { oldPath, newPath, hash }) => {
  const url = removeLinkedFileUrlParams(originalUrl);
  if (oldPath === newPath) {
    url.searchParams.set('file_path', oldPath);
  } else {
    url.searchParams.set('old_path', oldPath);
    url.searchParams.set('new_path', newPath);
  }
  if (hash) url.hash = hash;
  return url;
};
