import $ from 'jquery';
import { __ } from './locale';
import axios from './lib/utils/axios_utils';
import { deprecatedCreateFlash as flash } from './flash';

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
    const $parent = $checkbox.closest('.form-check');

    this.saveEvent($checkbox, $parent);
  }

  // eslint-disable-next-line class-methods-use-this
  showCheckboxLoadingSpinner($parent) {
    $parent
      .addClass('is-loading')
      .find('.custom-notification-event-loading')
      .removeClass('fa-check')
      .addClass('spinner align-middle')
      .removeClass('is-done');
  }

  saveEvent($checkbox, $parent) {
    const form = $parent.parents('form').first();

    this.showCheckboxLoadingSpinner($parent);

    axios[form.attr('method')](form.attr('action'), form.serialize())
      .then(({ data }) => {
        $checkbox.enable();
        if (data.saved) {
          $parent
            .find('.custom-notification-event-loading')
            .toggleClass('spinner fa-check is-done align-middle');
          setTimeout(() => {
            $parent
              .removeClass('is-loading')
              .find('.custom-notification-event-loading')
              .toggleClass('spinner fa-check is-done align-middle');
          }, 2000);
        }
      })
      .catch(() => flash(__('There was an error saving your notification settings.')));
  }
}
