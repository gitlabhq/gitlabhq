/* global merge_request_widget */

(() => {
  $(() => {
    /* TODO: This needs a better home, or should be refactored. It was previously contained
     * in a script tag in app/views/projects/merge_requests/widget/open/_accept.html.haml,
     * but Vue chokes on script tags and prevents their execution. So it was moved here
     * temporarily.
     * */

    if ($('.accept-mr-form').length) {
      $('.accept-mr-form').on('ajax:send', () => {
        $('.accept-mr-form :input').disable();
      });

      $('.accept_merge_request').on('click', () => {
        $('.js-merge-button').html('<i class="fa fa-spinner fa-spin"></i> Merge in progress');
      });

      $('.merge_when_build_succeeds').on('click', () => {
        $('#merge_when_build_succeeds').val('1');
      });

      $('.js-merge-dropdown a').on('click', (e) => {
        e.preventDefault();
        $(this).closest('form').submit();
      });
    } else if ($('.rebase-in-progress').length) {
      merge_request_widget.rebaseInProgress();
    } else if ($('.rebase-mr-form').length) {
      $('.rebase-mr-form').on('ajax:send', () => {
        $('.rebase-mr-form :input').disable();
      });

      $('.js-rebase-button').on('click', () => {
        $('.js-rebase-button').html("<i class='fa fa-spinner fa-spin'></i> Rebase in progress");
      });
    } else {
      merge_request_widget.getMergeStatus();
    }
  });
})();
