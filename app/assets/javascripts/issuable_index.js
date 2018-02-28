import IssuableBulkUpdateSidebar from './issuable_bulk_update_sidebar';
import IssuableBulkUpdateActions from './issuable_bulk_update_actions';

export default class IssuableIndex {
  constructor(pagePrefix) {
    this.initBulkUpdate(pagePrefix);
    IssuableIndex.resetIncomingEmailToken();
  }
  initBulkUpdate(pagePrefix) {
    const userCanBulkUpdate = $('.issues-bulk-update').length > 0;
    const alreadyInitialized = !!this.bulkUpdateSidebar;

    if (userCanBulkUpdate && !alreadyInitialized) {
      IssuableBulkUpdateActions.init({
        prefixId: pagePrefix,
      });

      this.bulkUpdateSidebar = new IssuableBulkUpdateSidebar();
    }
  }

  static resetIncomingEmailToken() {
    $('.incoming-email-token-reset').on('click', (e) => {
      e.preventDefault();

      $.ajax({
        type: 'PUT',
        url: $('.incoming-email-token-reset').attr('href'),
        dataType: 'json',
        success(response) {
          $('#issue_email').val(response.new_issue_address).focus();
        },
        beforeSend() {
          $('.incoming-email-token-reset').text('resetting...');
        },
        complete() {
          $('.incoming-email-token-reset').text('reset it');
        },
      });
    });
  }
}
