//= require vue
//= require_tree ./stores/
//= require ./components/environment
//= require ./vue_resource_interceptor


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
