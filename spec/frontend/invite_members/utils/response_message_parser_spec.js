import {
  responseFromSuccess,
  responseMessageFromError,
} from '~/invite_members/utils/response_message_parser';
import { invitationsApiResponse } from '../mock_data/api_responses';

describe('Response message parser', () => {
  const expectedMessage = 'expected display and message.';

  describe('parse message from successful response', () => {
    const exampleKeyedMsg = { 'email@example.com': expectedMessage };

    it.each([
      [{ data: { message: expectedMessage } }, { error: true, message: expectedMessage }],
      [{ data: { error: expectedMessage } }, { error: true, message: expectedMessage }],
      [{ data: { message: [expectedMessage] } }, { error: true, message: expectedMessage }],
      [{ data: { message: exampleKeyedMsg } }, { error: true, message: { ...exampleKeyedMsg } }],
    ])(`returns "${expectedMessage}" from success response: %j`, (successResponse, result) => {
      expect(responseFromSuccess(successResponse)).toStrictEqual(result);
    });
  });

  describe('message from error response', () => {
    it.each([
      [{ response: { data: { error: expectedMessage } } }],
      [{ response: { data: { message: { error: expectedMessage } } } }],
      [{ response: { data: { message: expectedMessage } } }],
    ])(`returns "${expectedMessage}" from error response: %j`, (errorResponse) => {
      expect(responseMessageFromError(errorResponse)).toBe(expectedMessage);
    });
  });

  describe('displaying all errors when a response has messages for multiple users', () => {
    it.each([
      [
        { data: invitationsApiResponse.MULTIPLE_RESTRICTED },
        { error: true, message: { ...invitationsApiResponse.MULTIPLE_RESTRICTED.message } },
      ],
      [
        { data: invitationsApiResponse.EMAIL_RESTRICTED },
        { error: true, message: { ...invitationsApiResponse.EMAIL_RESTRICTED.message } },
      ],
    ])(`returns "${expectedMessage}" from success response: %j`, (restrictedResponse, result) => {
      expect(responseFromSuccess(restrictedResponse)).toStrictEqual(result);
    });
  });
});
