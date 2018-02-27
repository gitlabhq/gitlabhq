import _ from 'underscore';
import createFlash from '~/flash';
import AccessorUtilities from '~/lib/utils/accessor';

const FLASH_QUEUE_KEY = 'flash-key';

export function popFlashMessage() {
  const page = $('body').attr('data-page');
  let savedFlashMessages;
  let returnVal = false;

  if (!page) {
    return returnVal;
  }

  if (AccessorUtilities.isLocalStorageAccessSafe()) {
    savedFlashMessages = JSON.parse(window.localStorage.getItem(FLASH_QUEUE_KEY));
    const queuedMessage = _.findWhere(savedFlashMessages, { bodyData: page });
    if (queuedMessage) {
      const queuedMessageIndex = _.findIndex(savedFlashMessages, { bodyData: page });
      createFlash(queuedMessage.message, queuedMessage.type);
      savedFlashMessages.splice(queuedMessageIndex, 1);
      window.localStorage.setItem(FLASH_QUEUE_KEY, JSON.stringify(savedFlashMessages));
    }
    returnVal = true;
  }

  return returnVal;
}

export function saveFlashMessage(bodyData, message, type) {
  let savedFlashMessages;

  if (AccessorUtilities.isLocalStorageAccessSafe()) {
    savedFlashMessages = JSON.parse(window.localStorage.getItem(FLASH_QUEUE_KEY));
    if (!savedFlashMessages) {
      savedFlashMessages = [];
    }
    savedFlashMessages.push({
      bodyData,
      message,
      type,
    });
    window.localStorage.setItem(FLASH_QUEUE_KEY, JSON.stringify(savedFlashMessages));
  }
}
