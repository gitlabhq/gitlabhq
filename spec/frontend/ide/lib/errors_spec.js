import {
  createUnexpectedCommitError,
  createCodeownersCommitError,
  createBranchChangedCommitError,
  parseCommitError,
} from '~/ide/lib/errors';

const TEST_SPECIAL = '&special<';
const TEST_SPECIAL_ESCAPED = '&amp;special&lt;';
const TEST_MESSAGE = 'Test message.';
const CODEOWNERS_MESSAGE =
  'Push to protected branches that contain changes to files matching CODEOWNERS is not allowed';
const CHANGED_MESSAGE = 'Things changed since you started editing';

describe('~/ide/lib/errors', () => {
  const createResponseError = message => ({
    response: {
      data: {
        message,
      },
    },
  });

  describe('createCodeownersCommitError', () => {
    it('uses given message', () => {
      expect(createCodeownersCommitError(TEST_MESSAGE)).toEqual({
        title: 'CODEOWNERS rule violation',
        messageHTML: TEST_MESSAGE,
        canCreateBranch: true,
      });
    });

    it('escapes special chars', () => {
      expect(createCodeownersCommitError(TEST_SPECIAL)).toEqual({
        title: 'CODEOWNERS rule violation',
        messageHTML: TEST_SPECIAL_ESCAPED,
        canCreateBranch: true,
      });
    });
  });

  describe('createBranchChangedCommitError', () => {
    it.each`
      message         | expectedMessage
      ${TEST_MESSAGE} | ${`${TEST_MESSAGE}<br/><br/>Would you like to create a new branch?`}
      ${TEST_SPECIAL} | ${`${TEST_SPECIAL_ESCAPED}<br/><br/>Would you like to create a new branch?`}
    `('uses given message="$message"', ({ message, expectedMessage }) => {
      expect(createBranchChangedCommitError(message)).toEqual({
        title: 'Branch changed',
        messageHTML: expectedMessage,
        canCreateBranch: true,
      });
    });
  });

  describe('parseCommitError', () => {
    it.each`
      message                                    | expectation
      ${null}                                    | ${createUnexpectedCommitError()}
      ${{}}                                      | ${createUnexpectedCommitError()}
      ${{ response: {} }}                        | ${createUnexpectedCommitError()}
      ${{ response: { data: {} } }}              | ${createUnexpectedCommitError()}
      ${createResponseError('test')}             | ${createUnexpectedCommitError()}
      ${createResponseError(CODEOWNERS_MESSAGE)} | ${createCodeownersCommitError(CODEOWNERS_MESSAGE)}
      ${createResponseError(CHANGED_MESSAGE)}    | ${createBranchChangedCommitError(CHANGED_MESSAGE)}
    `('parses message into error object with "$message"', ({ message, expectation }) => {
      expect(parseCommitError(message)).toEqual(expectation);
    });
  });
});
