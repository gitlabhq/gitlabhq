/**
 * setWindowLocation allows for setting `window.location` within Jest.
 *
 * The jsdom environment at the time of writing does not support changing the
 * current location (see
 * https://github.com/jsdom/jsdom/blob/16.4.0/lib/jsdom/living/window/navigation.js#L76),
 * hence this helper.
 *
 * This helper mutates the current `window.location` very similarly to how
 * a direct assignment to `window.location.href` would in a browser (but
 * without the navigation/reload behaviour). For instance:
 *
 * - Set the full href by passing an absolute URL, e.g.:
 *
 *     setWindowLocation('https://gdk.test');
 *     // window.location.href is now 'https://gdk.test'
 *
 * - Set the path, search and/or hash components by passing a relative URL:
 *
 *     setWindowLocation('/foo/bar');
 *     // window.location.href is now 'http://test.host/foo/bar'
 *
 *     setWindowLocation('?foo=bar');
 *     // window.location.href is now 'http://test.host/?foo=bar'
 *
 *     setWindowLocation('#foo');
 *     // window.location.href is now 'http://test.host/#foo'
 *
 *     setWindowLocation('/a/b/foo.html?bar=1#qux');
 *     // window.location.href is now 'http://test.host/a/b/foo.html?bar=1#qux
 *
 * Both approaches also automatically update the rest of the properties on
 * `window.location`. For instance:
 *
 *     setWindowLocation('http://test.host/a/b/foo.html?bar=1#qux');
 *     // window.location.origin is now 'http://test.host'
 *     // window.location.pathname is now '/a/b/foo.html'
 *     // window.location.search is now '?bar=1'
 *     // window.location.searchParams is now { bar: 1 }
 *     // window.location.hash is now '#qux'
 *
 * @param {string} url A string representing an absolute or relative URL.
 * @returns {undefined}
 */
export default function setWindowLocation(url) {
  if (typeof url !== 'string') {
    throw new TypeError(`Expected string; got ${url} (${typeof url})`);
  }

  const newUrl = new URL(url, window.location.href);

  global.jsdom.reconfigure({ url: newUrl.href });
}
