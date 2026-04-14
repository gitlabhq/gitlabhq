export const buildIframeUrl = (path, baseUrl, extraParams = null) => {
  if (!baseUrl) {
    return null;
  }
  try {
    const urlWithPath = new URL(path, baseUrl);
    if (extraParams) {
      // Remove any keys from the path's own query string that also appear in
      // extraParams so we never produce duplicate keys in the final URL.
      for (const key of extraParams.keys()) {
        urlWithPath.searchParams.delete(key);
      }
      for (const [key, value] of extraParams) {
        urlWithPath.searchParams.append(key, value);
      }
    }
    return urlWithPath.toString();
  } catch (error) {
    return baseUrl;
  }
};

export const extractTargetPath = (path, baseUrl) => {
  if (!path) {
    return null;
  }
  try {
    const url = new URL(path, baseUrl);
    return url.pathname;
  } catch (error) {
    return path;
  }
};
