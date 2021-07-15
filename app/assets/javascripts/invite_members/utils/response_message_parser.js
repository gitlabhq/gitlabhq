import { isString } from 'lodash';
import { API_MESSAGES } from '~/invite_members/constants';

function responseKeyedMessageParsed(keyedMessage) {
  try {
    const keys = Object.keys(keyedMessage);
    const msg = keyedMessage[keys[0]];

    if (msg === API_MESSAGES.EMAIL_ALREADY_INVITED) {
      return '';
    }
    return msg;
  } catch {
    return '';
  }
}
function responseMessageStringForMultiple(message) {
  return message.includes(':');
}
function responseMessageStringFirstPart(message) {
  return message.split(' and ')[0];
}

export function responseMessageFromError(response) {
  if (!response?.response?.data) {
    return '';
  }

  const {
    response: { data },
  } = response;

  return (
    data.error ||
    data.message?.user?.[0] ||
    data.message?.access_level?.[0] ||
    data.message?.error ||
    data.message ||
    ''
  );
}

export function responseMessageFromSuccess(response) {
  if (!response?.[0]?.data) {
    return '';
  }

  const { data } = response[0];

  if (data.message && !data.message.user) {
    const { message } = data;

    if (isString(message)) {
      if (responseMessageStringForMultiple(message)) {
        return responseMessageStringFirstPart(message);
      }

      return message;
    }

    return responseKeyedMessageParsed(message);
  }

  return data.message || data.message?.user || data.error || '';
}
