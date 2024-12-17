import { isEmpty, isString, isObject } from 'lodash';
import { sprintf, __ } from '~/locale';

const DEFAULT_ERROR = {
  message: __('Something went wrong. Please try again.'),
  links: {},
};

/**
 * @typedef {Object<ErrorAttribute,ErrorType[]>} ErrorAttributeMap - Map of attributes to error details
 * @typedef {string} ErrorAttribute - the error attribute https://api.rubyonrails.org/v7.0.4.2/classes/ActiveModel/Error.html
 * @typedef {string} ErrorType - the error type https://api.rubyonrails.org/v7.0.4.2/classes/ActiveModel/Error.html
 *
 * @example { "email": ["taken", ...] }
 * // returns `${UNLINKED_ACCOUNT_ERROR}`, i.e. the `EMAIL_TAKEN_ERROR_TYPE` error message
 *
 * @param {ErrorAttributeMap} errorAttributeMap
 * @param {Object} errorDictionary
 * @returns {(null|string)} null or error message if found
 */
function getMessageFromType(errorAttributeMap = {}, errorDictionary = {}) {
  if (!isObject(errorAttributeMap)) {
    return null;
  }

  return Object.keys(errorAttributeMap).reduce((_, attribute) => {
    const errorType = errorAttributeMap[attribute].find(
      (type) => errorDictionary[`${attribute}:${type}`.toLowerCase()],
    );
    if (errorType) {
      return errorDictionary[`${attribute}:${errorType}`.toLowerCase()];
    }

    return null;
  }, null);
}

/**
 * @param {String} cause
 * @param {Object} errorDictionary
 * @returns {(null|string)} null or error message if found
 */
function getMessageFromCause(cause, errorDictionary = {}) {
  if (!cause) {
    return null;
  }
  const errorType = errorDictionary[cause];
  if (!errorType) {
    return null;
  }

  return errorType;
}

/**
 * @example "Email has already been taken, Email is invalid"
 * // returns `${UNLINKED_ACCOUNT_ERROR}`, i.e. the `EMAIL_TAKEN_ERROR_TYPE` error message
 *
 * @param {string} errorString
 * @param {Object} errorDictionary
 * @returns {(null|string)} null or error message if found
 */
function getMessageFromErrorString(errorString, errorDictionary = {}) {
  if (isEmpty(errorString) || !isString(errorString)) {
    return null;
  }

  const messages = errorString.split(', ');
  const errorMessage = messages.find((message) => errorDictionary[message.toLowerCase()]);
  if (errorMessage) {
    return errorDictionary[errorMessage.toLowerCase()];
  }

  return {
    message: errorString,
    links: {},
  };
}

/**
 * Receives an Error and attempts to extract the `errorAttributeMap`
 * If a match is not found it will attempt to map a message from the
 * Error.message to be returned.
 * Otherwise, it will return a general error message.
 *
 * @param {Error|String} systemError
 * @param {Object} errorDictionary
 * @param {Object} defaultError
 * @returns error message
 */
export function mapSystemToFriendlyError(
  systemError,
  errorDictionary = {},
  defaultError = DEFAULT_ERROR,
) {
  if (systemError instanceof String || typeof systemError === 'string') {
    const messageFromErrorString = getMessageFromErrorString(systemError, errorDictionary);
    if (messageFromErrorString) {
      return messageFromErrorString;
    }
    return defaultError;
  }

  if (!(systemError instanceof Error)) {
    return defaultError;
  }

  const { errorAttributeMap, cause, message } = systemError;
  const messageFromType = getMessageFromType(errorAttributeMap, errorDictionary);
  if (messageFromType) {
    return messageFromType;
  }

  const messageFromCause = getMessageFromCause(cause, errorDictionary);
  if (messageFromCause) {
    return messageFromCause;
  }

  const messageFromErrorString = getMessageFromErrorString(message, errorDictionary);
  if (messageFromErrorString) {
    return messageFromErrorString;
  }

  return defaultError;
}

function generateLinks(links) {
  return Object.keys(links).reduce((allLinks, link) => {
    /* eslint-disable-next-line @gitlab/require-i18n-strings */
    const linkStart = `${link}Start`;
    /* eslint-disable-next-line @gitlab/require-i18n-strings */
    const linkEnd = `${link}End`;

    return {
      ...allLinks,
      [linkStart]: `<a href="${links[link]}" target="_blank" rel="noopener noreferrer">`,
      [linkEnd]: '</a>',
    };
  }, {});
}

export const generateHelpTextWithLinks = (error) => {
  if (isString(error)) {
    return error;
  }

  if (isEmpty(error)) {
    /* eslint-disable-next-line @gitlab/require-i18n-strings */
    throw new Error('The error cannot be empty.');
  }

  const links = generateLinks(error.links);
  return sprintf(error.message, links, false);
};

/**
 * Receives an error code and an error dictionary and returns true
 * if the error code is found in the dictionary and false otherwise.
 *
 * @param {String} errorCode
 * @param {Object} errorDictionary
 * @returns {Boolean}
 */
export const isKnownErrorCode = (errorCode, errorDictionary) => {
  if (errorCode instanceof String || typeof errorCode === 'string') {
    return Object.keys(errorDictionary).includes(errorCode.toLowerCase());
  }

  return false;
};
