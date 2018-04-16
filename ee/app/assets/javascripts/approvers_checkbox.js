import $ from 'jquery';

export default function initApproversCheckbox() {
  $('#require_approvals').on('change', e => {
    const $requiredApprovals = $('#project_approvals_before_merge');
    const enabled = $(e.target).prop('checked');
    const val = enabled ? 1 : 0;
    $requiredApprovals.val(val);
    $requiredApprovals.prop('min', val);
    $('.nested-settings').toggleClass('hidden', !enabled);
  });
}
