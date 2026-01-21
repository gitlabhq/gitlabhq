export const removeLinkedFileUrlParams = (originalUrl) => {
  const url = new URL(originalUrl, window.location);
  url.searchParams.delete('file_path');
  url.searchParams.delete('old_path');
  url.searchParams.delete('new_path');
  if (url.hash.startsWith('#line_')) url.hash = '';
  return url;
};
