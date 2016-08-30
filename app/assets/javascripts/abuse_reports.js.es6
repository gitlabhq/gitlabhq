((global) => {
  const MAX_MESSAGE_LENGTH = 500;
  const MESSAGE_CELL_SELECTOR = '.abuse-reports .message';

  class AbuseReports {
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
        $messageCellElement.data('original-message', reportMessage);
        $messageCellElement.data('message-truncated', 'true');
        $messageCellElement.text(global.text.truncate(reportMessage, MAX_MESSAGE_LENGTH));
      }
    }

    toggleMessageTruncation() {
      const $messageCellElement = $(this);
      const originalMessage = $messageCellElement.data('original-message');
      if (!originalMessage) return;
      if ($messageCellElement.data('message-truncated') === 'true') {
        $messageCellElement.data('message-truncated', 'false');
        $messageCellElement.text(originalMessage);
      } else {
        $messageCellElement.data('message-truncated', 'true');
        $messageCellElement.text(`${originalMessage.substr(0, (MAX_MESSAGE_LENGTH - 3))}...`);
      }
    }
  }

  global.AbuseReports = AbuseReports;
})(window.gl || (window.gl = {}));
