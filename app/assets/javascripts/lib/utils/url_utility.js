/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, no-param-reassign, no-cond-assign, one-var, one-var-declaration-per-line, no-void, guard-for-in, no-restricted-syntax, prefer-template, quotes, max-len */

var base;
var w = window;
if (w.gl == null) {
  w.gl = {};
}
if ((base = w.gl).utils == null) {
  base.utils = {};
}
// Returns an array containing the value(s) of the
// of the key passed as an argument
w.gl.utils.getParameterValues = function(sParam) {
  var i, sPageURL, sParameterName, sURLVariables, values;
  sPageURL = decodeURIComponent(window.location.search.substring(1));
  sURLVariables = sPageURL.split('&');
  sParameterName = void 0;
  values = [];
  i = 0;
  while (i < sURLVariables.length) {
    sParameterName = sURLVariables[i].split('=');
    if (sParameterName[0] === sParam) {
      values.push(sParameterName[1].replace(/\+/g, ' '));
    }
    i += 1;
  }
  return values;
};
// @param {Object} params - url keys and value to merge
// @param {String} url
w.gl.utils.mergeUrlParams = function(params, url) {
  var lastChar, newUrl, paramName, paramValue, pattern;
  newUrl = decodeURIComponent(url);
  for (paramName in params) {
    paramValue = params[paramName];
    pattern = new RegExp("\\b(" + paramName + "=).*?(&|$)");
    if (paramValue == null) {
      newUrl = newUrl.replace(pattern, '');
    } else if (url.search(pattern) !== -1) {
      newUrl = newUrl.replace(pattern, "$1" + paramValue + "$2");
    } else {
      newUrl = "" + newUrl + (newUrl.indexOf('?') > 0 ? '&' : '?') + paramName + "=" + paramValue;
    }
  }
  // Remove a trailing ampersand
  lastChar = newUrl[newUrl.length - 1];
  if (lastChar === '&') {
    newUrl = newUrl.slice(0, -1);
  }
  return newUrl;
};
// removes parameter query string from url. returns the modified url
w.gl.utils.removeParamQueryString = function(url, param) {
  var urlVariables, variables;
  url = decodeURIComponent(url);
  urlVariables = url.split('&');
  return ((function() {
    var j, len, results;
    results = [];
    for (j = 0, len = urlVariables.length; j < len; j += 1) {
      variables = urlVariables[j];
      if (variables.indexOf(param) === -1) {
        results.push(variables);
      }
    }
    return results;
  })()).join('&');
};
w.gl.utils.removeParams = (params) => {
  const url = document.createElement('a');
  url.href = window.location.href;
  params.forEach((param) => {
    url.search = w.gl.utils.removeParamQueryString(url.search, param);
  });
  return url.href;
};
w.gl.utils.getLocationHash = function(url) {
  var hashIndex;
  if (typeof url === 'undefined') {
    // Note: We can't use window.location.hash here because it's
    // not consistent across browsers - Firefox will pre-decode it
    url = window.location.href;
  }
  hashIndex = url.indexOf('#');
  return hashIndex === -1 ? null : url.substring(hashIndex + 1);
};

w.gl.utils.refreshCurrentPage = () => gl.utils.visitUrl(window.location.href);

// eslint-disable-next-line import/prefer-default-export
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

export function redirectTo(url) {
  return window.location.assign(url);
}

window.gl = window.gl || {};
window.gl.utils = {
  ...(window.gl.utils || {}),
  visitUrl,
};
