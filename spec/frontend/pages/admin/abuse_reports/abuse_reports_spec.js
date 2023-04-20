import $ from 'jquery';
import htmlAbuseReportsList from 'test_fixtures/abuse_reports/abuse_reports_list.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import AbuseReports from '~/pages/admin/abuse_reports/abuse_reports';

describe('Abuse Reports', () => {
  const MAX_MESSAGE_LENGTH = 500;

  let $messages;

  const assertMaxLength = ($message) => {
    expect($message.text().length).toEqual(MAX_MESSAGE_LENGTH);
  };
  const findMessage = (searchText) =>
    $messages.filter((index, element) => element.innerText.indexOf(searchText) > -1).first();

  beforeEach(() => {
    setHTMLFixture(htmlAbuseReportsList);
    new AbuseReports(); // eslint-disable-line no-new
    $messages = $('.abuse-reports .message');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('should truncate long messages', () => {
    const $longMessage = findMessage('LONG MESSAGE');

    expect($longMessage.data('originalMessage')).toEqual(expect.anything());
    assertMaxLength($longMessage);
  });

  it('should not truncate short messages', () => {
    const $shortMessage = findMessage('SHORT MESSAGE');

    expect($shortMessage.data('originalMessage')).not.toEqual(expect.anything());
  });

  it('should allow clicking a truncated message to expand and collapse the full message', () => {
    const $longMessage = findMessage('LONG MESSAGE');
    $longMessage.click();

    expect($longMessage.data('originalMessage').length).toEqual($longMessage.text().length);
    $longMessage.click();
    assertMaxLength($longMessage);
  });
});
