import { isString } from 'lodash';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

const normalizeKey = (autosaveKey) => {
  let normalizedKey;

  if (Array.isArray(autosaveKey) && autosaveKey.every(isString)) {
    normalizedKey = autosaveKey.join('/');
  } else if (isString(autosaveKey)) {
    normalizedKey = autosaveKey;
  } else {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('Invalid autosave key');
  }

  return `autosave/${normalizedKey}`;
};

const lockVersionKey = (autosaveKey) => `${normalizeKey(autosaveKey)}/lockVersion`;

export const clearDraft = (autosaveKey) => {
  try {
    window.localStorage.removeItem(normalizeKey(autosaveKey));
    window.localStorage.removeItem(lockVersionKey(autosaveKey));
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
  }
};

export const getDraft = (autosaveKey) => {
  try {
    return window.localStorage.getItem(normalizeKey(autosaveKey));
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    return null;
  }
};

export const getLockVersion = (autosaveKey) => {
  try {
    return window.localStorage.getItem(lockVersionKey(autosaveKey));
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    return null;
  }
};

export const updateDraft = (autosaveKey, text, lockVersion) => {
  try {
    window.localStorage.setItem(normalizeKey(autosaveKey), text);
    if (lockVersion) {
      window.localStorage.setItem(lockVersionKey(autosaveKey), lockVersion);
    }
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
  }
};

export const getDiscussionReplyKey = (noteableType, discussionId) =>
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  ['Note', capitalizeFirstCharacter(noteableType), discussionId, 'Reply'].join('/');

export const getAutoSaveKeyFromDiscussion = (discussion) =>
  getDiscussionReplyKey(discussion.notes.slice(0, 1)[0].noteable_type, discussion.id);
