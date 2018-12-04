// Returns an array containing the value(s) of the
// of the key passed as an argument
export function getParameterValues(sParam) {
  const sPageURL = decodeURIComponent(window.location.search.substring(1));

  return sPageURL.split('&').reduce((acc, urlParam) => {
    const sParameterName = urlParam.split('=');

    if (sParameterName[0] === sParam) {
      acc.push(sParameterName[1].replace(/\+/g, ' '));
    }

    return acc;
  }, []);
}

// @param {Object} params - url keys and value to merge
// @param {String} url
export function mergeUrlParams(params, url) {
  const re = /^([^?#]*)(\?[^#]*)?(.*)/;
  const merged = {};
  const urlparts = url.match(re);

  if (urlparts[2]) {
    urlparts[2]
      .substr(1)
      .split('&')
      .forEach(part => {
        if (part.length) {
          const kv = part.split('=');
          merged[decodeURIComponent(kv[0])] = decodeURIComponent(kv.slice(1).join('='));
        }
      });
  }

  Object.assign(merged, params);

  const query = Object.keys(merged)
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(merged[key])}`)
    .join('&');

  return `${urlparts[1]}?${query}${urlparts[3]}`;
}

export function removeParamQueryString(url, param) {
  const decodedUrl = decodeURIComponent(url);
  const urlVariables = decodedUrl.split('&');

  return urlVariables.filter(variable => variable.indexOf(param) === -1).join('&');
}

export function removeParams(params, source = window.location.href) {
  const url = document.createElement('a');
  url.href = source;

  params.forEach(param => {
    url.search = removeParamQueryString(url.search, param);
  });

  return url.href;
}

export function getLocationHash(url = window.location.href) {
  const hashIndex = url.indexOf('#');

  return hashIndex === -1 ? null : url.substring(hashIndex + 1);
}

export function visitUrl(url, external = false) {
  if (external) {
    // Simulate `target="blank" rel="noopener noreferrer"`
    // See https://mathiasbynens.github.io/rel-noopener/
    const otherWindow = window.open();
    otherWindow.opener = null;
    otherWindow.location = url;
  } else {
    window.location.href = url;
  }
}

export function refreshCurrentPage() {
  visitUrl(window.location.href);
}

export function redirectTo(url) {
  return window.location.assign(url);
}

export function webIDEUrl(route = undefined) {
  let returnUrl = `${gon.relative_url_root || ''}/-/ide/`;
  if (route) {
    returnUrl += `project${route.replace(new RegExp(`^${gon.relative_url_root || ''}`), '')}`;
  }
  return returnUrl;
}
