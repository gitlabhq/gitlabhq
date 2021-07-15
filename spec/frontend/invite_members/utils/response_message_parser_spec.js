import {
  responseMessageFromSuccess,
  responseMessageFromError,
} from '~/invite_members/utils/response_message_parser';

describe('Response message parser', () => {
  const expectedMessage = 'expected display message';

  describe('parse message from successful response', () => {
    const exampleKeyedMsg = { 'email@example.com': expectedMessage };
    const exampleUserMsgMultiple =
      ' and username1: id not found and username2: email is restricted';

    it.each([
      [[{ data: { message: expectedMessage } }]],
      [[{ data: { message: expectedMessage + exampleUserMsgMultiple } }]],
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
});
