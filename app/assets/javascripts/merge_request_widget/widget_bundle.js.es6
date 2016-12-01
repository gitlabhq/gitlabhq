//= require ./widget_store
//= require ./approvals/services/approvals_api
//= require ./approvals/approvals_bundle

((MergeRequestWidget) => {
  $(() => {
    const rootEl = document.getElementById('merge-request-widget-app');
    const store = new MergeRequestWidget.Store(rootEl);
    const components = MergeRequestWidget.Components;

    MergeRequestWidget.App = new Vue({
      el: rootEl,
      data: store.data,
      components: {
        'approvals-body': components.approvalsBody,
        'approvals-footer': components.approvalsFooter,
      },
    });
  });
})(gl.MergeRequestWidget || (gl.MergeRequestWidget = {}));
