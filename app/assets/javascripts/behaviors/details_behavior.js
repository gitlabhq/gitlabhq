import $ from 'jquery';

$(() => {
  $('body').on('click', '.js-details-target', function target() {
    $(this).closest('.js-details-container').toggleClass('open');
  });

  // Show details content. Hides link after click.
  //
  // %div
  //   %a.js-details-expand
  //   %div.js-details-content
  //
  $('body').on('click', '.js-details-expand', function expand(e) {
    e.preventDefault();
    $(this).next('.js-details-content').removeClass('hide');
    $(this).hide();

    const truncatedItem = $(this).siblings('.js-details-short');
    if (truncatedItem.length) {
      truncatedItem.addClass('hide');
    }
  });
});
