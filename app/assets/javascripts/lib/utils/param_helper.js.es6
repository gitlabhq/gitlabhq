/* eslint-disable no-param-reassign */

((gl) => {
  gl.utils = gl.utils || (gl.utils = {});

  /**
    this will take in the `name` of the param you want to parse in the url
    if the name does not exist this function will return `null`
    otherwise it will return the value of the param key provided
  */

  gl.utils.getParameterByName = (name) => {
    const url = window.location.href;
    name = name.replace(/[[\]]/g, '\\$&');
    const regex = new RegExp(`[?&]${name}(=([^&#]*)|&|#|$)`);
    const results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
  };
})(window.gl || (window.gl = {}));
