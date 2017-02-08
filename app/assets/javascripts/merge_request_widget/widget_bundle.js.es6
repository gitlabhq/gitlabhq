/* global merge_request_widget */
const Vue = require('vue');
require('./widget_store');
require('./approvals/approvals_bundle');

window.gl = window.gl || {};

$(() => {
  const rootEl = document.getElementById('merge-request-widget-app');
  const widgetSharedStore = new gl.MergeRequestWidgetStore(rootEl);

  gl.MergeRequestWidgetApp = new Vue({
    el: rootEl,
    data: widgetSharedStore.data,
  });
});
