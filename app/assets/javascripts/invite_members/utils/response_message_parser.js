import { isString, isArray } from 'lodash';

export function responseMessageFromError(response) {
  if (!response?.response?.data) {
    return '';
  }

  const {
    response: { data },
  } = response;

  return data.error || data.message?.error || data.message || '';
}

export function responseFromSuccess(response) {
  if (!response?.data) {
    return { error: false };
  }

  const { data } = response;

  if (data.message) {
    const { message } = data;

    if (isString(message)) {
      return { message, error: true };
    }

    if (isArray(message)) {
      return { message: message[0], error: true };
    }
    // we assume object now with our keyed format
    return { message: { ...message }, error: true };
  }

  if (data.error) {
    return { message: data.error, error: true };
  }

  return { error: false };
}
