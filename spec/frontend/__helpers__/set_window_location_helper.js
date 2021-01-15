/**
 * setWindowLocation allows for setting `window.location`
 * (doing so directly is causing an error in jsdom)
 *
 * Example usage:
 * assert(window.location.hash === undefined);
 * setWindowLocation('http://example.com#foo')
 * assert(window.location.hash === '#foo');
 *
 * More information:
 * https://github.com/facebook/jest/issues/890
 *
 * @param url
 */
export default function setWindowLocation(url) {
  const parsedUrl = new URL(url);

  const newLocationValue = [
    'hash',
    'host',
    'hostname',
    'href',
    'origin',
    'pathname',
    'port',
    'protocol',
    'search',
  ].reduce(
    (location, prop) => ({
      ...location,
      [prop]: parsedUrl[prop],
    }),
    {},
  );

  Object.defineProperty(window, 'location', {
    value: newLocationValue,
    writable: true,
  });
}
