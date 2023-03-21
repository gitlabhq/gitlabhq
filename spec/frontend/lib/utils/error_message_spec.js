import { parseErrorMessage, USER_FACING_ERROR_MESSAGE_PREFIX } from '~/lib/utils/error_message';

const defaultErrorMessage = 'Default error message';
const errorMessage = 'Returned error message';

const generateErrorWithMessage = (message) => {
  return {
    message,
  };
};

describe('parseErrorMessage', () => {
  it.each`
    error                                                    | expectedResult
    ${`${USER_FACING_ERROR_MESSAGE_PREFIX} ${errorMessage}`} | ${errorMessage}
    ${`${errorMessage} ${USER_FACING_ERROR_MESSAGE_PREFIX}`} | ${defaultErrorMessage}
    ${errorMessage}                                          | ${defaultErrorMessage}
    ${undefined}                                             | ${defaultErrorMessage}
    ${''}                                                    | ${defaultErrorMessage}
  `(
    'properly parses "$error" error object and returns "$expectedResult"',
    ({ error, expectedResult }) => {
      const errorObject = generateErrorWithMessage(error);
      expect(parseErrorMessage(errorObject, defaultErrorMessage)).toEqual(expectedResult);
    },
  );

  it.each`
    error                                                                              | defaultMessage         | expectedResult
    ${undefined}                                                                       | ${defaultErrorMessage} | ${defaultErrorMessage}
    ${''}                                                                              | ${defaultErrorMessage} | ${defaultErrorMessage}
    ${{}}                                                                              | ${defaultErrorMessage} | ${defaultErrorMessage}
    ${generateErrorWithMessage(errorMessage)}                                          | ${undefined}           | ${''}
    ${generateErrorWithMessage(`${USER_FACING_ERROR_MESSAGE_PREFIX} ${errorMessage}`)} | ${undefined}           | ${errorMessage}
    ${generateErrorWithMessage(errorMessage)}                                          | ${''}                  | ${''}
    ${generateErrorWithMessage(`${USER_FACING_ERROR_MESSAGE_PREFIX} ${errorMessage}`)} | ${''}                  | ${errorMessage}
  `(
    'properly handles the edge case of error="$error" and defaultMessage="$defaultMessage"',
    ({ error, defaultMessage, expectedResult }) => {
      expect(parseErrorMessage(error, defaultMessage)).toEqual(expectedResult);
    },
  );
});
