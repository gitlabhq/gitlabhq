/**
 * Checks if the provided URL is a safe URL (absolute http(s) URL)
 *
 * @param {String} url that will be checked
 * @returns {Boolean}
 */
export default url => {
  let parsedUrl;

  if (!(url.startsWith('https:') || url.startsWith('http:'))) {
    return false;
  }

  /*
   Trying to use URL constructor, IE11 does not support it, so we fall back on the a element trick
   */
  try {
    parsedUrl = new URL(url);
  } catch (e) {
    parsedUrl = document.createElement('a');
    parsedUrl.href = url;
  }

  return ['http:', 'https:'].includes(parsedUrl.protocol);
};
