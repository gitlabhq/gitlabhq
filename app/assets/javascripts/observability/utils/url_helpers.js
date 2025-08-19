export const buildIframeUrl = (path, baseUrl) => {
  if (!baseUrl) {
    return null;
  }
  try {
    const urlWithPath = new URL(path, baseUrl);
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
