import AccessorUtilities from '~/lib/utils/accessor';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import {
  savedViewDraftStorageKey,
  getSavedViewDraft,
  saveSavedViewDraft,
  clearSavedViewDraft,
} from '~/work_items/list/saved_view_draft';

describe('saved view draft localStorage', () => {
  useLocalStorageSpy();

  const context = { rootPageFullPath: 'group/project', viewId: '42' };
  const storageKey = 'group/project-saved-view-42';
  const draft = { sortKey: 'CREATED_DESC', displaySettings: { foo: 'bar' }, viewMode: 'LIST' };

  beforeEach(() => {
    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
  });

  describe('savedViewDraftStorageKey', () => {
    it('builds the key from the namespace path and view id', () => {
      expect(savedViewDraftStorageKey(context)).toBe(storageKey);
    });
  });

  describe('saveSavedViewDraft', () => {
    it('serializes the draft under the computed key', () => {
      saveSavedViewDraft(context, draft);

      expect(localStorage.setItem).toHaveBeenCalledWith(storageKey, JSON.stringify(draft));
    });

    it('does not write when localStorage is unavailable', () => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);

      saveSavedViewDraft(context, draft);

      expect(localStorage.setItem).not.toHaveBeenCalled();
    });

    it('does not throw when localStorage throws (e.g. quota exceeded)', () => {
      localStorage.setItem.mockImplementation(() => {
        throw new Error('QuotaExceededError');
      });

      expect(() => saveSavedViewDraft(context, draft)).not.toThrow();
    });
  });

  describe('getSavedViewDraft', () => {
    it('returns the parsed draft when present', () => {
      saveSavedViewDraft(context, draft);

      expect(getSavedViewDraft(context)).toEqual(draft);
    });

    it('returns null when no draft is stored', () => {
      expect(getSavedViewDraft(context)).toBeNull();
    });

    it('returns null when the stored value is not valid JSON', () => {
      // getStorageValue warns on parse failure before falling back; silence it.
      jest.spyOn(console, 'warn').mockImplementation(() => {});
      localStorage.setItem(storageKey, '{ not json');

      expect(getSavedViewDraft(context)).toBeNull();
    });

    it('returns null when localStorage is unavailable', () => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);

      expect(getSavedViewDraft(context)).toBeNull();
    });
  });

  describe('clearSavedViewDraft', () => {
    it('removes the draft under the computed key', () => {
      clearSavedViewDraft(context);

      expect(localStorage.removeItem).toHaveBeenCalledWith(storageKey);
    });

    it('does not remove when localStorage is unavailable', () => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);

      clearSavedViewDraft(context);

      expect(localStorage.removeItem).not.toHaveBeenCalled();
    });

    it('does not throw when localStorage throws', () => {
      localStorage.removeItem.mockImplementation(() => {
        throw new Error('SecurityError');
      });

      expect(() => clearSavedViewDraft(context)).not.toThrow();
    });
  });
});
