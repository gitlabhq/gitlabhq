import { clearDraft, getDraft, updateDraft, getLockVersion } from '~/lib/utils/autosave';

describe('autosave utils', () => {
  const autosaveKey = 'dummy-autosave-key';
  const text = 'some dummy text';
  const lockVersion = '2';
  const normalizedAutosaveKey = `autosave/${autosaveKey}`;
  const lockVersionKey = `autosave/${autosaveKey}/lockVersion`;

  describe('clearDraft', () => {
    beforeEach(() => {
      localStorage.setItem(normalizedAutosaveKey, text);
      localStorage.setItem(lockVersionKey, lockVersion);
    });

    afterEach(() => {
      localStorage.removeItem(normalizedAutosaveKey);
    });

    it('removes the draft from localStorage', () => {
      clearDraft(autosaveKey);

      expect(localStorage.getItem(normalizedAutosaveKey)).toBe(null);
    });

    it('removes the lockVersion from localStorage', () => {
      clearDraft(autosaveKey);

      expect(localStorage.getItem(lockVersionKey)).toBe(null);
    });
  });

  describe('getDraft', () => {
    beforeEach(() => {
      localStorage.setItem(normalizedAutosaveKey, text);
    });

    afterEach(() => {
      localStorage.removeItem(normalizedAutosaveKey);
    });

    it('returns the draft from localStorage', () => {
      const result = getDraft(autosaveKey);

      expect(result).toBe(text);
    });

    it('returns null if no entry exists in localStorage', () => {
      localStorage.removeItem(normalizedAutosaveKey);

      const result = getDraft(autosaveKey);

      expect(result).toBe(null);
    });
  });

  describe('updateDraft', () => {
    beforeEach(() => {
      localStorage.setItem(normalizedAutosaveKey, text);
    });

    afterEach(() => {
      localStorage.removeItem(normalizedAutosaveKey);
    });

    it('updates the stored draft', () => {
      const newText = 'new text';

      updateDraft(autosaveKey, newText);

      expect(localStorage.getItem(normalizedAutosaveKey)).toBe(newText);
    });

    describe('when lockVersion is provided', () => {
      it('updates the stored lockVersion', () => {
        const newText = 'new text';
        const newLockVersion = '2';

        updateDraft(autosaveKey, newText, lockVersion);

        expect(localStorage.getItem(lockVersionKey)).toBe(newLockVersion);
      });
    });
  });

  describe('getLockVersion', () => {
    beforeEach(() => {
      localStorage.setItem(lockVersionKey, lockVersion);
    });

    afterEach(() => {
      localStorage.removeItem(lockVersionKey);
    });

    it('returns the lockVersion from localStorage', () => {
      expect(getLockVersion(autosaveKey)).toBe(lockVersion);
    });
  });
});
