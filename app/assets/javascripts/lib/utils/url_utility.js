(function() {
  (function(w) {
    var base;
    if (w.gl == null) {
      w.gl = {};
    }
    if ((base = w.gl).utils == null) {
      base.utils = {};
    }
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
          values.push(sParameterName[1]);
        }
        i++;
      }
      return values;
    };
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
      lastChar = newUrl[newUrl.length - 1];
      if (lastChar === '&') {
        newUrl = newUrl.slice(0, -1);
      }
      return newUrl;
    };
    w.gl.utils.removeParamQueryString = function(url, param) {
      var urlVariables, variables;
      url = decodeURIComponent(url);
      urlVariables = url.split('&');
      return ((function() {
        var j, len, results;
        results = [];
        for (j = 0, len = urlVariables.length; j < len; j++) {
          variables = urlVariables[j];
          if (variables.indexOf(param) === -1) {
            results.push(variables);
          }
        }
        return results;
      })()).join('&');
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
  })(window);

}).call(this);
