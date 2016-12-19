/* global Vue */
//= require ./widget_store
//= require ./approvals/approvals_bundle

(() => {
  $(() => {
    const rootEl = document.getElementById('merge-request-widget-app');
    const widgetSharedStore = new gl.MergeRequestWidgetStore(rootEl);

    gl.MergeRequestWidgetApp = new Vue({
      el: rootEl,
      data: widgetSharedStore.data,
    });
  });
})(window.gl || (window.gl = {}));
