import $ from 'jquery';
import { truncate } from '../../../lib/utils/text_utility';

const MAX_MESSAGE_LENGTH = 500;
const MESSAGE_CELL_SELECTOR = '.abuse-reports .message';

export default class AbuseReports {
  constructor() {
    $(MESSAGE_CELL_SELECTOR).each(this.truncateLongMessage);
    $(document)
      .off('click', MESSAGE_CELL_SELECTOR)
      .on('click', MESSAGE_CELL_SELECTOR, this.toggleMessageTruncation);
  }

  truncateLongMessage() {
    const $messageCellElement = $(this);
    const reportMessage = $messageCellElement.text();
    if (reportMessage.length > MAX_MESSAGE_LENGTH) {
      $messageCellElement.data('originalMessage', reportMessage);
      $messageCellElement.data('messageTruncated', 'true');
      $messageCellElement.text(truncate(reportMessage, MAX_MESSAGE_LENGTH));
    }
  }

  toggleMessageTruncation() {
    const $messageCellElement = $(this);
    const originalMessage = $messageCellElement.data('originalMessage');
    if (!originalMessage) return;
    if ($messageCellElement.data('messageTruncated') === 'true') {
      $messageCellElement.data('messageTruncated', 'false');
      $messageCellElement.text(originalMessage);
    } else {
      $messageCellElement.data('messageTruncated', 'true');
      $messageCellElement.text(`${originalMessage.substr(0, (MAX_MESSAGE_LENGTH - 3))}...`);
    }
  }
}
