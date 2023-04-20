import { parseErrorMessage } from '~/lib/utils/error_message';

const defaultErrorMessage = 'Default error message';
const errorMessage = 'Returned error message';

const generateErrorWithMessage = (message) => {
  return {
    message,
  };
};

describe('parseErrorMessage', () => {
  const ufErrorPrefix = 'Foo:';
  beforeEach(() => {
    gon.uf_error_prefix = ufErrorPrefix;
  });

  it.each`
    error                                 | expectedResult
    ${`${ufErrorPrefix} ${errorMessage}`} | ${errorMessage}
    ${`${errorMessage} ${ufErrorPrefix}`} | ${defaultErrorMessage}
    ${errorMessage}                       | ${defaultErrorMessage}
    ${undefined}                          | ${defaultErrorMessage}
    ${''}                                 | ${defaultErrorMessage}
  `(
    'properly parses "$error" error object and returns "$expectedResult"',
    ({ error, expectedResult }) => {
      const errorObject = generateErrorWithMessage(error);
      expect(parseErrorMessage(errorObject, defaultErrorMessage)).toEqual(expectedResult);
    },
  );

  it.each`
    error                                                           | defaultMessage         | expectedResult
    ${undefined}                                                    | ${defaultErrorMessage} | ${defaultErrorMessage}
    ${''}                                                           | ${defaultErrorMessage} | ${defaultErrorMessage}
    ${{}}                                                           | ${defaultErrorMessage} | ${defaultErrorMessage}
    ${generateErrorWithMessage(errorMessage)}                       | ${undefined}           | ${''}
    ${generateErrorWithMessage(`${ufErrorPrefix} ${errorMessage}`)} | ${undefined}           | ${errorMessage}
    ${generateErrorWithMessage(errorMessage)}                       | ${''}                  | ${''}
    ${generateErrorWithMessage(`${ufErrorPrefix} ${errorMessage}`)} | ${''}                  | ${errorMessage}
  `(
    'properly handles the edge case of error="$error" and defaultMessage="$defaultMessage"',
    ({ error, defaultMessage, expectedResult }) => {
      expect(parseErrorMessage(error, defaultMessage)).toEqual(expectedResult);
    },
  );
});
