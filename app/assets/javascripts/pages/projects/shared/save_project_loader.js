import $ from 'jquery';

export default function initProjectLoadingSpinner() {
  const $formContainer = $('.project-edit-container');
  const $loadingSpinner = $('.save-project-loader');

  // show loading spinner when saving
  $formContainer.on('ajax:before', () => {
    $formContainer.hide();
    $loadingSpinner.show();
  });
}
