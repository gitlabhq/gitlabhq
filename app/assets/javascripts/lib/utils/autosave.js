import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export const clearDraft = (autosaveKey) => {
  try {
    window.localStorage.removeItem(`autosave/${autosaveKey}`);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
  }
};

export const getDraft = (autosaveKey) => {
  try {
    return window.localStorage.getItem(`autosave/${autosaveKey}`);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    return null;
  }
};

export const updateDraft = (autosaveKey, text) => {
  try {
    window.localStorage.setItem(`autosave/${autosaveKey}`, text);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
  }
};

export const getDiscussionReplyKey = (noteableType, discussionId) =>
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  ['Note', capitalizeFirstCharacter(noteableType), discussionId, 'Reply'].join('/');
