function getUrlParameter(sParam) {
  var sPageURL = decodeURIComponent(window.location.search.substring(1)),
      sURLVariables = sPageURL.split('&'),
      sParameterName,
      i;

  for (i = 0; i < sURLVariables.length; i++) {
    sParameterName = sURLVariables[i].split('=');

    if (sParameterName[0] === sParam) {
      return sParameterName[1] === undefined ? true : sParameterName[1];
    }
  }
}

/**
 * @param {Object} params - url keys and value to merge
 * @param {String} url
 */
function mergeUrlParams(params, url){
  var newUrl = decodeURIComponent(url);

  Object.keys(params).forEach(function(paramName) {
    var pattern = new RegExp('\\b('+paramName+'=).*?(&|$)')
    if (url.search(pattern) >= 0){
      newUrl = newUrl.replace(pattern,'$1' + params[paramName] + '$2');
    } else {
      newUrl = newUrl + (newUrl.indexOf('?') > 0 ? '&' : '?') + paramName + '=' + params[paramName]
    }
  });

  return newUrl;
}