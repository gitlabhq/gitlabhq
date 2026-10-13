const ETAG_RESOURCE_HEADER = 'x-gitlab-graphql-resource-etag';
const MAX_ENTRIES = 50;

const findHeader = (headers, name) => {
  const key = Object.keys(headers).find((k) => k.toLowerCase() === name);
  return key ? headers[key] : undefined;
};

/**
 * Wraps `fetch` so eTag-cached GraphQL queries can be sent as POST.
 *
 * GET would let the browser handle `If-None-Match`, but puts the whole query in the URL,
 * which proxies and WAFs with URL size limits reject. The browser does not cache POST,
 * so we keep the last eTag and body per request and replay the body on a 304.
 */
export const createEtagFetch = (fetchFn) => {
  const entries = new Map();

  const etagFetch = async (url, options, resource) => {
    // The server eTag covers the whole resource, so the key must also include the body
    // (query and variables), just as the browser keys GET entries by URL.
    const key = `${resource}:${options.body}`;
    const cached = entries.get(key);
    const requestOptions = cached
      ? { ...options, headers: { ...options.headers, 'If-None-Match': cached.etag } }
      : options;

    const response = await fetchFn(url, requestOptions);

    if (response.status === 304 && cached) {
      entries.delete(key);
      entries.set(key, cached);

      // Keep the 304's headers (fresh request ID, X-Gitlab-From-Cache) but restore the body's type.
      const headers = new Headers(response.headers);
      if (cached.contentType) headers.set('content-type', cached.contentType);

      return new Response(cached.body, { status: 200, statusText: 'OK', headers });
    }

    const etag = response.headers.get('etag');

    if (response.ok && etag) {
      entries.delete(key);
      entries.set(key, {
        etag,
        body: await response.clone().text(),
        contentType: response.headers.get('content-type'),
      });

      if (entries.size > MAX_ENTRIES) {
        entries.delete(entries.keys().next().value);
      }
    }

    return response;
  };

  // Stay synchronous for pass-through requests so wrapping `fetch` doesn't change their timing.
  return (url, options = {}) => {
    const resource = findHeader(options.headers || {}, ETAG_RESOURCE_HEADER);

    if (!resource || options.method === 'GET' || typeof options.body !== 'string') {
      return fetchFn(url, options);
    }

    return etagFetch(url, options, resource);
  };
};
