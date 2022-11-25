(() => {
  const CACHE_NAME = 'INTERCEPTOR_CACHE';

  /**
   * Fetches and parses JSON from the sessionStorage cache
   * @returns {(Object)}
   */
  const getCache = () => {
    return JSON.parse(sessionStorage.getItem(CACHE_NAME));
  };

  /**
   * Commits an object to the sessionStorage cache
   * @param {Object} data
   */
  const saveCache = (data) => {
    sessionStorage.setItem(CACHE_NAME, JSON.stringify(data));
  };

  /**
   * Checks if the cache is available
   * and if the current context has access to it
   * @returns {boolean} can we access the cache?
   */
  const checkCache = () => {
    try {
      getCache();
      return true;
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn(`Couldn't access cache: ${error.toString()}`);
      return false;
    }
  };

  /**
   * @callback cacheCommitCallback
   * @param {object} cache
   * @return {object} mutated cache
   */

  /**
   * If the cache is available, takes a callback function that is called
   * with an object returned from getCache,
   * and saves whatever is returned from the callback function
   * to the cache
   * @param {cacheCommitCallback} cb
   */
  const commitToCache = (cb) => {
    if (checkCache()) {
      const cache = cb(getCache());
      saveCache(cache);
    }
  };

  window.Interceptor = {
    saveCache,
    commitToCache,
    getCache,
    checkCache,
    activeFetchRequests: 0,
  };

  const pureFetch = window.fetch;
  const pureXHROpen = window.XMLHttpRequest.prototype.open;

  /**
   * Replacement for XMLHttpRequest.prototype.open
   * listens for complete xhr events
   * if the xhr response has a status code higher than 400
   * then commit request/response metadata to the cache
   * @param method intercepted HTTP method (GET|POST|etc..)
   * @param url intercepted HTTP url
   * @param args intercepted XHR arguments (credentials, headers, options
   * @return {Promise} the result of the original XMLHttpRequest.prototype.open implementation
   */
  function interceptXhr(method, url, ...args) {
    this.addEventListener(
      'readystatechange',
      () => {
        const self = this;
        if (this.readyState === XMLHttpRequest.DONE) {
          if (this.status >= 400 || this.status === 0) {
            commitToCache((cache) => {
              // eslint-disable-next-line no-param-reassign
              cache.errors ||= [];
              cache.errors.push({
                status: self.status === 0 ? -1 : self.status,
                url,
                method,
                headers: { 'x-request-id': self.getResponseHeader('x-request-id') },
              });
              return cache;
            });
          }
        }
      },
      false,
    );
    return pureXHROpen.apply(this, [method, url, ...args]);
  }

  /**
   * @param url - the URL
   * @param method - the REST method
   * @param clonedResponse - a cloned fetch response
   * @return {Promise<void>}
   */
  async function checkForGraphQLErrors(url, method, clonedResponse) {
    if (/api\/graphql/.test(url)) {
      const body = await clonedResponse.json();
      if (body.errors && body.errors instanceof Array) {
        const errorMessages = body.errors.map((error) => error.message);

        commitToCache((cache) => {
          // eslint-disable-next-line no-param-reassign
          cache.errors ||= [];
          cache.errors.push({
            status: clonedResponse.status,
            url,
            method,
            errorData: `error-messages: ${errorMessages.join(', ')}`,
            headers: { 'x-request-id': clonedResponse.headers.get('x-request-id') },
          });
          return cache;
        });
      }
    }
  }

  /**
   * Replacement for fetch implementation
   * tracks active requests, and commits metadata to the cache
   * if the response is not ok or was cancelled.
   * Additionally tracks activeFetchRequests on the Interceptor object
   * @param url target HTTP url
   * @param opts fetch options, including request method, body, etc
   * @param args additional fetch arguments
   * @returns {Promise<"success"|"error">} the result of the original fetch call
   */
  async function interceptedFetch(url, opts, ...args) {
    const method = opts && opts.method ? opts.method : 'GET';
    window.Interceptor.activeFetchRequests += 1;
    try {
      const response = await pureFetch(url, opts, ...args);
      const clone = response.clone();

      if (!clone.ok) {
        commitToCache((cache) => {
          // eslint-disable-next-line no-param-reassign
          cache.errors ||= [];
          cache.errors.push({
            status: clone.status,
            url,
            method,
            headers: { 'x-request-id': clone.headers.get('x-request-id') },
          });
          return cache;
        });
      }

      await checkForGraphQLErrors(url, method, clone);

      return response;
    } catch (error) {
      commitToCache((cache) => {
        // eslint-disable-next-line no-param-reassign
        cache.errors ||= [];
        cache.errors.push({
          status: -1,
          url,
          method,
        });
        return cache;
      });

      throw error;
    } finally {
      window.Interceptor.activeFetchRequests += -1;
    }
  }

  /**
   * Initializes the cache
   * if the cache doesn't already exist.
   */
  const initCache = () => {
    if (checkCache() && getCache() == null) {
      saveCache({});
    }
  };

  // Initialize cache on page load.
  initCache();

  window.fetch = interceptedFetch;
  window.XMLHttpRequest.prototype.open = interceptXhr;
})();
