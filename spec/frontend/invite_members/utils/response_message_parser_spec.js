import {
  responseMessageFromSuccess,
  responseMessageFromError,
} from '~/invite_members/utils/response_message_parser';
import { membersApiResponse, invitationsApiResponse } from '../mock_data/api_responses';

describe('Response message parser', () => {
  const expectedMessage = 'expected display and message.';

  describe('parse message from successful response', () => {
    const exampleKeyedMsg = { 'email@example.com': expectedMessage };
    const exampleFirstPartMultiple = 'username1: expected display and message.';
    const exampleUserMsgMultiple =
      ' and username2: id not found and restricted email. and username3: email is restricted.';

    it.each([
      [[{ data: { message: expectedMessage } }]],
      [[{ data: { message: exampleFirstPartMultiple + exampleUserMsgMultiple } }]],
      [[{ data: { error: expectedMessage } }]],
      [[{ data: { message: [expectedMessage] } }]],
      [[{ data: { message: exampleKeyedMsg } }]],
    ])(`returns "${expectedMessage}" from success response: %j`, (successResponse) => {
      expect(responseMessageFromSuccess(successResponse)).toBe(expectedMessage);
    });
  });

  describe('message from error response', () => {
    it.each([
      [{ response: { data: { error: expectedMessage } } }],
      [{ response: { data: { message: { user: [expectedMessage] } } } }],
      [{ response: { data: { message: { access_level: [expectedMessage] } } } }],
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
      [[{ data: membersApiResponse.MULTIPLE_USERS_RESTRICTED }]],
      [[{ data: invitationsApiResponse.MULTIPLE_EMAIL_RESTRICTED }]],
      [[{ data: invitationsApiResponse.EMAIL_RESTRICTED }]],
    ])(`returns "${expectedMessage}" from success response: %j`, (restrictedResponse) => {
      expect(responseMessageFromSuccess(restrictedResponse)).toBe(expected);
    });

    it.each([[{ response: { data: membersApiResponse.SINGLE_USER_RESTRICTED } }]])(
      `returns "${expectedMessage}" from error response: %j`,
      (singleRestrictedResponse) => {
        expect(responseMessageFromError(singleRestrictedResponse)).toBe(expected);
      },
    );
  });
});
