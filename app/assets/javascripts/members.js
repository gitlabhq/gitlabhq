import $ from 'jquery';
import { Rails } from '~/lib/utils/rails_ujs';
import { disableButtonIfEmptyField } from '~/lib/utils/common_utils';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import { __, sprintf } from '~/locale';

export default class Members {
  constructor() {
    this.addListeners();
    this.initGLDropdown();
  }

  addListeners() {
    $('.js-member-update-control')
      .off('change')
      .on('change', this.formSubmit.bind(this));
    $('.js-edit-member-form')
      .off('ajax:success')
      .on('ajax:success', this.formSuccess.bind(this));
    disableButtonIfEmptyField('#user_ids', 'input[name=commit]', 'change');
  }

  dropdownClicked(options) {
    options.e.preventDefault();

    this.formSubmit(null, options.$el);
  }

  // eslint-disable-next-line class-methods-use-this
  dropdownToggleLabel(selected, $el) {
    return $el.text();
  }

  // eslint-disable-next-line class-methods-use-this
  dropdownIsSelectable(selected, $el) {
    return !$el.hasClass('is-active');
  }

  initGLDropdown() {
    $('.js-member-permissions-dropdown').each((i, btn) => {
      const $btn = $(btn);

      initDeprecatedJQueryDropdown($btn, {
        selectable: true,
        isSelectable: (selected, $el) => this.dropdownIsSelectable(selected, $el),
        fieldName: $btn.data('fieldName'),
        id(selected, $el) {
          return $el.data('id');
        },
        toggleLabel: (selected, $el) => this.dropdownToggleLabel(selected, $el, $btn),
        clicked: options => this.dropdownClicked(options),
      });
    });
  }

  formSubmit(e, $el = null) {
    const $this = e ? $(e.currentTarget) : $el;
    const { $toggle, $dateInput } = this.getMemberListItems($this);
    const formEl = $this.closest('form').get(0);

    Rails.fire(formEl, 'submit');

    $toggle.disable();
    $dateInput.disable();
  }

  formSuccess(e) {
    const { $toggle, $dateInput, $expiresIn, $expiresInText } = this.getMemberListItems(
      $(e.currentTarget).closest('.js-member'),
    );

    const [data] = e.detail;
    const expiresIn = data?.expires_in;

    if (expiresIn) {
      $expiresIn.removeClass('gl-display-none');

      $expiresInText.text(sprintf(__('Expires in %{expires_at}'), { expires_at: expiresIn }));

      const { expires_soon: expiresSoon, expires_at_formatted: expiresAtFormatted } = data;

      if (expiresSoon) {
        $expiresInText.addClass('text-warning');
      } else {
        $expiresInText.removeClass('text-warning');
      }

      // Update tooltip
      if (expiresAtFormatted) {
        $expiresInText.attr('title', expiresAtFormatted);
        $expiresInText.attr('data-original-title', expiresAtFormatted);
      }
    } else {
      $expiresIn.addClass('gl-display-none');
    }

    $toggle.enable();
    $dateInput.enable();
  }

  // eslint-disable-next-line class-methods-use-this
  getMemberListItems($el) {
    const $memberListItem = $el.is('.js-member') ? $el : $(`#${$el.data('elId')}`);

    return {
      $memberListItem,
      $expiresIn: $memberListItem.find('.js-expires-in'),
      $expiresInText: $memberListItem.find('.js-expires-in-text'),
      $toggle: $memberListItem.find('.dropdown-menu-toggle'),
      $dateInput: $memberListItem.find('.js-access-expiration-date'),
    };
  }
}
