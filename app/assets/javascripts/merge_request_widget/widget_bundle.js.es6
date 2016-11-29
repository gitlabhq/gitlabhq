//= require ./stores/widget_store
//= require ./services/widget_service
//= require ./approvals/approvals_bundle
/**
 * 
 * 'data-approved-by-users' => @merge_request.approved_by_users.to_json, 'data-approver-names' => @merge_request.approvers.to_json,'data-approvals-left' => @merge_request.approvals_left, 'data-more-approvals' => (@merge_request.approvals_left - @merge_request.approvers_left.count), 'data-can-approve' => @merge_request.user_is_approver(current_user), 'data-endpoint'=> '/myendpoint/tho' }
 * 
 */
$(() => {
  // Move initialization to somewhere else -- all can be conducted before DOM ready
  new gl.MergeRequestWidgetStore();
  new gl.MergeRequestWidgetService();
  
  const app = gl.MergeRequestWidget;
  
  new Vue({
    el: '#merge-request-widget-app',
    data: Store.data,
    components: {
      'approvals-body': app.approvalsBody,
      'approvals-footer': app.approvalsFooter
    }
  });
});
/**
 * 
 *  gl.MergeRequestWidgetApp
 *    Store
 *    ApiService
 *    
 * 
 *  TODO: Add documentation for registering new widget components 
 * 
 */
// Need list of approved by, list of those who can approve, and the number required