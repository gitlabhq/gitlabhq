import AccessorUtilities from '~/lib/utils/accessor';
import { getStorageValue, saveStorageValue, removeStorageValue } from '~/lib/utils/local_storage';

// localStorage persistence for unsaved changes to a saved view, keyed per
// namespace + view so each view keeps its own draft. Access is guarded so
// unavailable storage (private mode, quota) degrades gracefully, not throws.

export const savedViewDraftStorageKey = ({ rootPageFullPath, viewId }) =>
  `${rootPageFullPath}-saved-view-${viewId}`;

export const getSavedViewDraft = (context) => {
  if (!AccessorUtilities.canUseLocalStorage()) return null;

  const { exists, value } = getStorageValue(savedViewDraftStorageKey(context));
  return exists ? value : null;
};

export const saveSavedViewDraft = (context, draftData) => {
  if (!AccessorUtilities.canUseLocalStorage()) return;

  try {
    saveStorageValue(savedViewDraftStorageKey(context), draftData);
  } catch {
    // Storage may be unavailable (e.g. quota or private mode); ignore.
  }
};

export const clearSavedViewDraft = (context) => {
  if (!AccessorUtilities.canUseLocalStorage()) return;

  try {
    removeStorageValue(savedViewDraftStorageKey(context));
  } catch {
    // Storage may be unavailable (e.g. quota or private mode); ignore.
  }
};
