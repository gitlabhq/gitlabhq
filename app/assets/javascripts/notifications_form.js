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
    $parent.find('.is-loading').removeClass('gl-display-none');
    $parent.find('.is-done').addClass('gl-display-none');
  }

  saveEvent($checkbox, $parent) {
    const form = $parent.parents('form').first();

    this.showCheckboxLoadingSpinner($parent);

    axios[form.attr('method')](form.attr('action'), form.serialize())
      .then(({ data }) => {
        $checkbox.enable();
        if (data.saved) {
          $parent.find('.is-loading').addClass('gl-display-none');
          $parent.find('.is-done').removeClass('gl-display-none');

          setTimeout(() => {
            $parent.find('.is-done').addClass('gl-display-none');
          }, 2000);
        }
      })
      .catch(() => flash(__('There was an error saving your notification settings.')));
  }
}
