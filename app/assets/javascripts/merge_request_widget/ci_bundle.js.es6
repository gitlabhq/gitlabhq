/* global merge_request_widget */

(() => {
  $(() => {
    /* TODO: This needs a better home, or should be refactored. It was previously contained
     * in a script tag in app/views/projects/merge_requests/widget/open/_accept.html.haml,
     * but Vue chokes on script tags and prevents their execution. So it was moved here
     * temporarily.
     * */

    if ($('.accept-mr-form').length) {
      $('.accept-mr-form').off('ajax:send.acceptMRSend')
        .on('ajax:send.acceptMRSend', () => {
          $('.accept-mr-form :input').disable();
        });

      $('.accept_merge_request').off('click.mergeInProgress')
        .on('click.mergeInProgress', () => {
          $('.js-merge-button').html('<i class="fa fa-spinner fa-spin"></i> Merge in progress');
        });

      $('.merge_when_build_succeeds').off('click.whenBuildSucceeds')
        .on('click.whenBuildSucceeds', () => {
          $('#merge_when_build_succeeds').val('1');
        });

      $('.js-merge-dropdown a').off('click.mergeMRSubmit')
        .on('click.mergeMRSubmit', (e) => {
          e.preventDefault();
          $(this).closest('form').submit();
        });
    } else if ($('.rebase-in-progress').length) {
      merge_request_widget.rebaseInProgress();
    } else if ($('.rebase-mr-form').length) {
      $('.rebase-mr-form').off('ajax:send.rebaseMRSend')
        .on('ajax:send.rebaseMRSend', () => {
          $('.rebase-mr-form :input').disable();
        });

      $('.js-rebase-button').off('click.rebaseInProgress')
        .on('click.rebaseInProgress', () => {
          $('.js-rebase-button').html("<i class='fa fa-spinner fa-spin'></i> Rebase in progress");
        });
    } else {
      merge_request_widget.getMergeStatus();
    }
  });
})();
