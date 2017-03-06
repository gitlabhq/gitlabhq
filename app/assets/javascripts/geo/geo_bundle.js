/* global Vue */

window.Vue = require('vue');
require('./components/geo_clone_dialog');

$(document).ready(() => {
  window.gl = window.gl || {};
  const $geoClone = document.getElementById('geo-clone');

  if ($geoClone) {
    gl.GeoClone = new Vue({
      el: $geoClone,
      components: {
        'geo-clone-dialog': gl.geo.CloneDialog,
      },
      data: Object.assign({}, $geoClone.dataset),
    });
  }
});
