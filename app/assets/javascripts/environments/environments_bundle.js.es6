const EnvironmentsComponent = require('./components/environment');

$(() => {
  window.gl = window.gl || {};

  if (gl.EnvironmentsListApp) {
    gl.EnvironmentsListApp.$destroy(true);
  }

  gl.EnvironmentsListApp = new EnvironmentsComponent({
    el: document.querySelector('#environments-list-view'),
  });
});
