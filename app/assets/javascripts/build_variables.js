/* eslint-disable func-names*/

export default function handleRevealVariables() {
  $('.js-reveal-variables')
    .off('click')
    .on('click', function () {
      $('.js-build-variables').toggle();
      $(this).hide();
    });
}
