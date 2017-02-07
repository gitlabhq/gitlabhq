window.Vue = require('vue');
require('./stores/environments_store');
require('./components/environment');
require('../vue_shared/vue_resource_interceptor');

$(() => {
  window.gl = window.gl || {};

  if (gl.EnvironmentsListApp) {
    gl.EnvironmentsListApp.$destroy(true);
  }
  const Store = gl.environmentsList.EnvironmentsStore;

  gl.EnvironmentsListApp = new gl.environmentsList.EnvironmentsComponent({
    el: document.querySelector('#environments-list-view'),

    propsData: {
      store: Store.create(),
    },

  });
});
