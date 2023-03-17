import { parseErrorMessage, USER_FACING_ERROR_MESSAGE_PREFIX } from '~/lib/utils/error_message';

const defaultErrorMessage = 'Something caused this error';
const userFacingErrorMessage = 'User facing error message';
const nonUserFacingErrorMessage = 'NonUser facing error message';
const genericErrorMessage = 'Some error message';

describe('error message', () => {
  describe('when given an errormessage object', () => {
    const errorMessageObject = {
      options: {
        cause: defaultErrorMessage,
      },
      filename: 'error.js',
      linenumber: 7,
    };

    it('returns the correct values for userfacing errors', () => {
      const userFacingObject = errorMessageObject;
      userFacingObject.message = `${USER_FACING_ERROR_MESSAGE_PREFIX} ${userFacingErrorMessage}`;

      expect(parseErrorMessage(userFacingObject)).toEqual({
        message: userFacingErrorMessage,
        userFacing: true,
      });
    });

    it('returns the correct values for non userfacing errors', () => {
      const nonUserFacingObject = errorMessageObject;
      nonUserFacingObject.message = nonUserFacingErrorMessage;

      expect(parseErrorMessage(nonUserFacingObject)).toEqual({
        message: nonUserFacingErrorMessage,
        userFacing: false,
      });
    });
  });

  describe('when given an errormessage string', () => {
    it('returns the correct values for userfacing errors', () => {
      expect(
        parseErrorMessage(`${USER_FACING_ERROR_MESSAGE_PREFIX} ${genericErrorMessage}`),
      ).toEqual({
        message: genericErrorMessage,
        userFacing: true,
      });
    });

    it('returns the correct values for non userfacing errors', () => {
      expect(parseErrorMessage(genericErrorMessage)).toEqual({
        message: genericErrorMessage,
        userFacing: false,
      });
    });
  });

  describe('when given nothing', () => {
    it('returns an empty error message', () => {
      expect(parseErrorMessage()).toEqual({
        message: '',
        userFacing: false,
      });
    });
  });
});
