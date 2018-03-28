import project from '../../ide/stores/mutations/project';

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
  let newUrl = Object.keys(params).reduce((acc, paramName) => {
    const paramValue = encodeURIComponent(params[paramName]);
    const pattern = new RegExp(`\\b(${paramName}=).*?(&|$)`);

    if (paramValue === null) {
      return acc.replace(pattern, '');
    } else if (url.search(pattern) !== -1) {
      return acc.replace(pattern, `$1${paramValue}$2`);
    }

    return `${acc}${acc.indexOf('?') > 0 ? '&' : '?'}${paramName}=${paramValue}`;
  }, decodeURIComponent(url));

  // Remove a trailing ampersand
  const lastChar = newUrl[newUrl.length - 1];

  if (lastChar === '&') {
    newUrl = newUrl.slice(0, -1);
  }

  return newUrl;
}

export function removeParamQueryString(url, param) {
  const decodedUrl = decodeURIComponent(url);
  const urlVariables = decodedUrl.split('&');

  return urlVariables.filter(variable => variable.indexOf(param) === -1).join('&');
}

export function removeParams(params) {
  const url = document.createElement('a');
  url.href = window.location.href;

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

export function webIDEUrl(projectUrl = undefined) {
  let returnUrl = `${gon.relative_url_root}/-/ide/`;
  if (projectUrl) {
    returnUrl += `project${projectUrl}`;
  }
  return returnUrl;
}
