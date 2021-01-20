import {
  createUnexpectedCommitError,
  createCodeownersCommitError,
  createBranchChangedCommitError,
  branchAlreadyExistsCommitError,
  parseCommitError,
} from '~/ide/lib/errors';

const TEST_SPECIAL = '&special<';
const TEST_SPECIAL_ESCAPED = '&amp;special&lt;';
const TEST_MESSAGE = 'Test message.';
const CODEOWNERS_MESSAGE =
  'Push to protected branches that contain changes to files matching CODEOWNERS is not allowed';
const CHANGED_MESSAGE = 'Things changed since you started editing';

describe('~/ide/lib/errors', () => {
  const createResponseError = (message) => ({
    response: {
      data: {
        message,
      },
    },
  });

  const NEW_BRANCH_SUFFIX = `<br/><br/>Would you like to create a new branch?`;
  const AUTOGENERATE_SUFFIX = `<br/><br/>Would you like to try auto-generating a branch name?`;

  it.each`
    fn                                | title                          | message         | messageHTML
    ${createCodeownersCommitError}    | ${'CODEOWNERS rule violation'} | ${TEST_MESSAGE} | ${TEST_MESSAGE}
    ${createCodeownersCommitError}    | ${'CODEOWNERS rule violation'} | ${TEST_SPECIAL} | ${TEST_SPECIAL_ESCAPED}
    ${branchAlreadyExistsCommitError} | ${'Branch already exists'}     | ${TEST_MESSAGE} | ${`${TEST_MESSAGE}${AUTOGENERATE_SUFFIX}`}
    ${branchAlreadyExistsCommitError} | ${'Branch already exists'}     | ${TEST_SPECIAL} | ${`${TEST_SPECIAL_ESCAPED}${AUTOGENERATE_SUFFIX}`}
    ${createBranchChangedCommitError} | ${'Branch changed'}            | ${TEST_MESSAGE} | ${`${TEST_MESSAGE}${NEW_BRANCH_SUFFIX}`}
    ${createBranchChangedCommitError} | ${'Branch changed'}            | ${TEST_SPECIAL} | ${`${TEST_SPECIAL_ESCAPED}${NEW_BRANCH_SUFFIX}`}
  `('$fn escapes and uses given message="$message"', ({ fn, title, message, messageHTML }) => {
    expect(fn(message)).toEqual({
      title,
      messageHTML,
      primaryAction: { text: 'Create new branch', callback: expect.any(Function) },
    });
  });

  describe('parseCommitError', () => {
    it.each`
      message                                    | expectation
      ${null}                                    | ${createUnexpectedCommitError()}
      ${{}}                                      | ${createUnexpectedCommitError()}
      ${{ response: {} }}                        | ${createUnexpectedCommitError()}
      ${{ response: { data: {} } }}              | ${createUnexpectedCommitError()}
      ${createResponseError(TEST_MESSAGE)}       | ${createUnexpectedCommitError(TEST_MESSAGE)}
      ${createResponseError(CODEOWNERS_MESSAGE)} | ${createCodeownersCommitError(CODEOWNERS_MESSAGE)}
      ${createResponseError(CHANGED_MESSAGE)}    | ${createBranchChangedCommitError(CHANGED_MESSAGE)}
    `('parses message into error object with "$message"', ({ message, expectation }) => {
      expect(parseCommitError(message)).toEqual(expectation);
    });
  });
});
