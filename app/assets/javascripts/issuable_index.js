import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import flash from './flash';
import { s__, __ } from './locale';
import IssuableBulkUpdateSidebar from './issuable_bulk_update_sidebar';
import IssuableBulkUpdateActions from './issuable_bulk_update_actions';

export default class IssuableIndex {
  constructor(pagePrefix) {
    this.initBulkUpdate(pagePrefix);
    IssuableIndex.resetIncomingEmailToken();
  }
  initBulkUpdate(pagePrefix) {
    const userCanBulkUpdate = $('.issues-bulk-update').length > 0;
    const alreadyInitialized = Boolean(this.bulkUpdateSidebar);

    if (userCanBulkUpdate && !alreadyInitialized) {
      IssuableBulkUpdateActions.init({
        prefixId: pagePrefix,
      });

      this.bulkUpdateSidebar = new IssuableBulkUpdateSidebar();
    }
  }

  static resetIncomingEmailToken() {
    const $resetToken = $('.incoming-email-token-reset');

    $resetToken.on('click', e => {
      e.preventDefault();

      $resetToken.text(s__('EmailToken|resetting...'));

      axios
        .put($resetToken.attr('href'))
        .then(({ data }) => {
          $('#issuable_email')
            .val(data.new_address)
            .focus();

          $resetToken.text(s__('EmailToken|reset it'));
        })
        .catch(() => {
          flash(__('There was an error when reseting email token.'));

          $resetToken.text(s__('EmailToken|reset it'));
        });
    });
  }
}
