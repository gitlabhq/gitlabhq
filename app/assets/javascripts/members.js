import $ from 'jquery';

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
    gl.utils.disableButtonIfEmptyField('#user_ids', 'input[name=commit]', 'change');
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

      $btn.glDropdown({
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

    $this.closest('form').trigger('submit.rails');

    $toggle.disable();
    $dateInput.disable();
  }

  formSuccess(e) {
    const { $toggle, $dateInput } = this.getMemberListItems($(e.currentTarget).closest('.member'));

    $toggle.enable();
    $dateInput.enable();
  }

  // eslint-disable-next-line class-methods-use-this
  getMemberListItems($el) {
    const $memberListItem = $el.is('.member') ? $el : $(`#${$el.data('elId')}`);

    return {
      $memberListItem,
      $toggle: $memberListItem.find('.dropdown-menu-toggle'),
      $dateInput: $memberListItem.find('.js-access-expiration-date'),
    };
  }
}
