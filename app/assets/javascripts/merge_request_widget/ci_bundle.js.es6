$(() => {
  /* TODO: This needs a better home, or should be refactored. It was previously contained
   * in a script tag in app/views/projects/merge_requests/widget/open/_accept.html.haml,
   * but Vue chokes on script tags and prevents their execution. So it was moved here
   * temporarily.
   * */

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
});
