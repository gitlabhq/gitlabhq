export const USER_FACING_ERROR_MESSAGE_PREFIX = 'UF:';

const getMessageFromError = (error = '') => {
  return error.message || error;
};

export const parseErrorMessage = (error = '') => {
  const messageString = getMessageFromError(error);

  if (messageString.startsWith(USER_FACING_ERROR_MESSAGE_PREFIX)) {
    return {
      message: messageString.replace(USER_FACING_ERROR_MESSAGE_PREFIX, '').trim(),
      userFacing: true,
    };
  }
  return {
    message: messageString,
    userFacing: false,
  };
};
