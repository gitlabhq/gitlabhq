export default class NotificationsForm {
  constructor() {
    this.toggleCheckbox = this.toggleCheckbox.bind(this);
    this.initEventListeners();
  }

  initEventListeners() {
    $(document).on('change', '.js-custom-notification-event', this.toggleCheckbox);
  }

  toggleCheckbox(e) {
    const $checkbox = $(e.currentTarget);
    const $parent = $checkbox.closest('.checkbox');

    this.saveEvent($checkbox, $parent);
  }

  // eslint-disable-next-line class-methods-use-this
  showCheckboxLoadingSpinner($parent) {
    $parent.addClass('is-loading')
      .find('.custom-notification-event-loading')
      .removeClass('fa-check')
      .addClass('fa-spin fa-spinner')
      .removeClass('is-done');
  }

  saveEvent($checkbox, $parent) {
    const form = $parent.parents('form:first');

    return $.ajax({
      url: form.attr('action'),
      method: form.attr('method'),
      dataType: 'json',
      data: form.serialize(),
      beforeSend: () => {
        this.showCheckboxLoadingSpinner($parent);
      },
    }).done((data) => {
      $checkbox.enable();
      if (data.saved) {
        $parent.find('.custom-notification-event-loading').toggleClass('fa-spin fa-spinner fa-check is-done');
        setTimeout(() => {
          $parent.removeClass('is-loading')
            .find('.custom-notification-event-loading')
            .toggleClass('fa-spin fa-spinner fa-check is-done');
        }, 2000);
      }
    });
  }
}
