//= require ./stores/widget_store
//= require ./approvals/approvals_bundle

$(() => {
  const el = document.getElementById('merge-request-widget-app');
  const Store = new gl.MergeRequestWidgetStore(el);
  const app = gl.MergeRequestWidget;

  new Vue({
    el,
    data: Store.data,
    components: {
      'approvals-body' : app.approvalsBody,
      'approvals-footer' : app.approvalsFooter
    },
    methods: {
      unapproveMergeRequest() {
        console.log("Parent instance Unapprove MR");
      },
      approveMergeRequest() {
        console.log("Parent instance Approve MR");
      }
    },
  });
});
