import {
  responseMessageFromSuccess,
  responseMessageFromError,
} from '~/invite_members/utils/response_message_parser';
import { invitationsApiResponse } from '../mock_data/api_responses';

describe('Response message parser', () => {
  const expectedMessage = 'expected display and message.';

  describe('parse message from successful response', () => {
    const exampleKeyedMsg = { 'email@example.com': expectedMessage };

    it.each([
      [{ data: { message: expectedMessage } }],
      [{ data: { error: expectedMessage } }],
      [{ data: { message: [expectedMessage] } }],
      [{ data: { message: exampleKeyedMsg } }],
    ])(`returns "${expectedMessage}" from success response: %j`, (successResponse) => {
      expect(responseMessageFromSuccess(successResponse)).toBe(expectedMessage);
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

  describe('displaying only the first error when a response has messages for multiple users', () => {
    const expected =
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.";

    it.each([
      [{ data: invitationsApiResponse.MULTIPLE_RESTRICTED }],
      [{ data: invitationsApiResponse.EMAIL_RESTRICTED }],
    ])(`returns "${expectedMessage}" from success response: %j`, (restrictedResponse) => {
      expect(responseMessageFromSuccess(restrictedResponse)).toBe(expected);
    });
  });
});
