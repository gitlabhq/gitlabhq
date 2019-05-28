import { clearDraft, getDraft, updateDraft } from '~/lib/utils/autosave';

describe('autosave utils', () => {
  const autosaveKey = 'dummy-autosave-key';
  const text = 'some dummy text';

  describe('clearDraft', () => {
    beforeEach(() => {
      localStorage.setItem(`autosave/${autosaveKey}`, text);
    });

    afterEach(() => {
      localStorage.removeItem(`autosave/${autosaveKey}`);
    });

    it('removes the draft from localStorage', () => {
      clearDraft(autosaveKey);

      expect(localStorage.getItem(`autosave/${autosaveKey}`)).toBe(null);
    });
  });

  describe('getDraft', () => {
    beforeEach(() => {
      localStorage.setItem(`autosave/${autosaveKey}`, text);
    });

    afterEach(() => {
      localStorage.removeItem(`autosave/${autosaveKey}`);
    });

    it('returns the draft from localStorage', () => {
      const result = getDraft(autosaveKey);

      expect(result).toBe(text);
    });

    it('returns null if no entry exists in localStorage', () => {
      localStorage.removeItem(`autosave/${autosaveKey}`);

      const result = getDraft(autosaveKey);

      expect(result).toBe(null);
    });
  });

  describe('updateDraft', () => {
    beforeEach(() => {
      localStorage.setItem(`autosave/${autosaveKey}`, text);
    });

    afterEach(() => {
      localStorage.removeItem(`autosave/${autosaveKey}`);
    });

    it('removes the draft from localStorage', () => {
      const newText = 'new text';

      updateDraft(autosaveKey, newText);

      expect(localStorage.getItem(`autosave/${autosaveKey}`)).toBe(newText);
    });
  });
});
