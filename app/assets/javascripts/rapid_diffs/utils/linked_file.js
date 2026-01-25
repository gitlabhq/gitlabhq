export const removeLinkedFileUrlParams = (originalUrl) => {
  const url = new URL(originalUrl, window.location);
  url.searchParams.delete('file_path');
  url.searchParams.delete('old_path');
  url.searchParams.delete('new_path');
  if (url.hash.startsWith('#line_')) url.hash = '';
  return url;
};

export const withLinkedFileUrlParams = (originalUrl, { oldPath, newPath }) => {
  const url = removeLinkedFileUrlParams(originalUrl);
  if (oldPath === newPath) {
    url.searchParams.set('file_path', oldPath);
  } else {
    url.searchParams.set('old_path', oldPath);
    url.searchParams.set('new_path', newPath);
  }
  return url;
};
