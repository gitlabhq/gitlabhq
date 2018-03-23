import $ from 'jquery';

export default class AjaxLoadingSpinner {
  static init() {
    const $elements = $('.js-ajax-loading-spinner');

    $elements.on('ajax:beforeSend', AjaxLoadingSpinner.ajaxBeforeSend);
    $elements.on('ajax:complete', AjaxLoadingSpinner.ajaxComplete);
  }

  static ajaxBeforeSend(e) {
    e.target.setAttribute('disabled', '');
    const iconElement = e.target.querySelector('i');
    // get first fa- icon
    const originalIcon = iconElement.className.match(/(fa-)([^\s]+)/g)[0];
    iconElement.dataset.icon = originalIcon;
    AjaxLoadingSpinner.toggleLoadingIcon(iconElement);
    $(e.target).off('ajax:beforeSend', AjaxLoadingSpinner.ajaxBeforeSend);
  }

  static ajaxComplete(e) {
    e.target.removeAttribute('disabled');
    const iconElement = e.target.querySelector('i');
    AjaxLoadingSpinner.toggleLoadingIcon(iconElement);
    $(e.target).off('ajax:complete', AjaxLoadingSpinner.ajaxComplete);
  }

  static toggleLoadingIcon(iconElement) {
    const classList = iconElement.classList;
    classList.toggle(iconElement.dataset.icon);
    classList.toggle('fa-spinner');
    classList.toggle('fa-spin');
  }
}
