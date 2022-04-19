import { isString } from 'lodash';

function responseKeyedMessageParsed(keyedMessage) {
  try {
    const keys = Object.keys(keyedMessage);
    const msg = keyedMessage[keys[0]];

    return msg;
  } catch {
    return '';
  }
}

export function responseMessageFromError(response) {
  if (!response?.response?.data) {
    return '';
  }

  const {
    response: { data },
  } = response;

  return data.error || data.message?.error || data.message || '';
}

export function responseMessageFromSuccess(response) {
  if (!response?.data) {
    return '';
  }

  const { data } = response;

  if (data.message) {
    const { message } = data;

    if (isString(message)) {
      return message;
    }

    return responseKeyedMessageParsed(message);
  }

  return data.error || '';
}
