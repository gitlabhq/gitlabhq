import $ from 'jquery';
import _ from 'underscore';

export default () => {
  $('.approver-list').on('click', '.unsaved-approvers.approver .btn-remove', function approverListClickCallback(ev) {
    const removeElement = $(this).closest('li');
    const approverId = parseInt(removeElement.attr('id').replace('user_', ''), 10);
    const approverIds = $('input#merge_request_approver_ids');
    const skipUsers = approverIds.data('skipUsers') || [];
    const approverIndex = skipUsers.indexOf(approverId);

    removeElement.remove();

    if (approverIndex > -1) {
      approverIds.data('skipUsers', skipUsers.splice(approverIndex, 1));
    }

    ev.preventDefault();
  });

  $('.approver-list').on('click', '.unsaved-approvers.approver-group .btn-remove', function approverListRemoveClickCallback(ev) {
    const removeElement = $(this).closest('li');
    const approverGroupId = parseInt(removeElement.attr('id').replace('group_', ''), 10);
    const approverGroupIds = $('input#merge_request_approver_group_ids');
    const skipGroups = approverGroupIds.data('skipGroups') || [];
    const approverGroupIndex = skipGroups.indexOf(approverGroupId);

    removeElement.remove();

    if (approverGroupIndex > -1) {
      approverGroupIds.data('skipGroups', skipGroups.splice(approverGroupIndex, 1));
    }

    ev.preventDefault();
  });

  $('form.merge-request-form').on('submit', function mergeRequestFormSubmitCallback() {
    if ($('input#merge_request_approver_ids').length) {
      let approverIds = $.map($('li.unsaved-approvers.approver').not('.approver-template'), li => li.id.replace('user_', ''));
      const approversInput = $(this).find('input#merge_request_approver_ids');
      approverIds = approverIds.concat(approversInput.val().split(','));
      approversInput.val(_.compact(approverIds).join(','));
    }

    if ($('input#merge_request_approver_group_ids').length) {
      let approverGroupIds = $.map($('li.unsaved-approvers.approver-group'), li => li.id.replace('group_', ''));
      const approverGroupsInput = $(this).find('input#merge_request_approver_group_ids');
      approverGroupIds = approverGroupIds.concat(approverGroupsInput.val().split(','));
      approverGroupsInput.val(_.compact(approverGroupIds).join(','));
    }
  });

  $('.suggested-approvers a').on('click', function sugestedApproversClickCallback() {
    const userId = this.id.replace('user_', '');
    const username = this.text;

    if ($(`.approver-list #user_${userId}`).length) {
      return false;
    }

    const approverItemHTML = $('.unsaved-approvers.approver-template').clone()
      .removeClass('hide approver-template')[0]
      .outerHTML.replace(/\{approver_name\}/g, username).replace(/\{user_id\}/g, userId);
    $('.no-approvers').remove();
    $('.approver-list').append(approverItemHTML);

    return false;
  });
};
