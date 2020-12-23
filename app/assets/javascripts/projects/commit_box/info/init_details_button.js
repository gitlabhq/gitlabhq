import $ from 'jquery';

export const initDetailsButton = () => {
  $('body').on('click', '.js-details-expand', function expand(e) {
    e.preventDefault();
    $(this).next('.js-details-content').removeClass('hide');
    $(this).hide();
  });
};
