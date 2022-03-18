import { unescape } from 'lodash';
import { sanitize } from '~/lib/dompurify';
import { INVALID_FEEDBACK_MESSAGE_DEFAULT } from '../constants';
import { responseMessageFromError } from './response_message_parser';

const unescapeMsg = (message) => unescape(sanitize(message, { ALLOWED_TAGS: [] }));

export const getInvalidFeedbackMessage = (response) => {
  const message = unescapeMsg(responseMessageFromError(response));

  return message || INVALID_FEEDBACK_MESSAGE_DEFAULT;
};
