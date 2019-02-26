export const clearDraft = autosaveKey => {
  try {
    window.localStorage.removeItem(`autosave/${autosaveKey}`);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
  }
};

export const getDraft = autosaveKey => {
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
