import $ from 'jquery';

export default class AjaxLoadingSpinner {
  static init() {
    const $elements = $('.js-ajax-loading-spinner');
    $elements.on('ajax:beforeSend', AjaxLoadingSpinner.ajaxBeforeSend);
  }

  static ajaxBeforeSend(e) {
    const button = e.target;
    const newButton = document.createElement('button');
    newButton.classList.add('btn', 'btn-default', 'disabled', 'gl-button');
    newButton.setAttribute('disabled', 'disabled');

    const spinner = document.createElement('span');
    spinner.classList.add('align-text-bottom', 'gl-spinner', 'gl-spinner-sm', 'gl-spinner-orange');
    newButton.appendChild(spinner);

    button.classList.add('hidden');
    button.parentNode.insertBefore(newButton, button.nextSibling);

    $(button).one('ajax:error', () => {
      newButton.remove();
      button.classList.remove('hidden');
    });

    $(button).one('ajax:success', () => {
      $(button).off('ajax:beforeSend', AjaxLoadingSpinner.ajaxBeforeSend);
    });
  }
}
