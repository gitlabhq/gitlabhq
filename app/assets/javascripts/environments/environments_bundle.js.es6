//= require vue
//= require_tree ./stores/
//= require ./components/environment
//= require ./vue_resource_interceptor


$(() => {
  window.gl = window.gl || {};

  if (window.gl.EnvironmentsListApp) {
    window.gl.EnvironmentsListApp.$destroy(true);
  }
  const Store = window.gl.environmentsList.EnvironmentsStore;

  window.gl.EnvironmentsListApp = new window.gl.environmentsList.EnvironmentsComponent({
    el: document.querySelector('#environments-list-view'),
    propsData: {
      store: Store.create(),
    },
  });
});
