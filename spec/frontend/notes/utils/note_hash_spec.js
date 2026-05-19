import { getNoteIdFromHash, discussionsContainNote } from '~/notes/utils/note_hash';
import { getLocationHash } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');

describe('note_hash utils', () => {
  describe('getNoteIdFromHash', () => {
    it('returns note ID as a string when hash contains note_', () => {
      getLocationHash.mockReturnValue('note_123');
      expect(getNoteIdFromHash()).toBe('123');
    });

    it('returns null when hash does not start with note_', () => {
      getLocationHash.mockReturnValue('diff_abc123');
      expect(getNoteIdFromHash()).toBeNull();
    });

    it('returns null when hash is undefined', () => {
      getLocationHash.mockReturnValue(undefined);
      expect(getNoteIdFromHash()).toBeNull();
    });

    it('returns null when hash is empty', () => {
      getLocationHash.mockReturnValue('');
      expect(getNoteIdFromHash()).toBeNull();
    });

    it('returns non-numeric note ID as string', () => {
      getLocationHash.mockReturnValue('note_abc');
      expect(getNoteIdFromHash()).toBe('abc');
    });
  });

  describe('discussionsContainNote', () => {
    it('returns true when a discussion contains the note', () => {
      const discussions = [{ notes: [{ id: 1 }, { id: 2 }] }, { notes: [{ id: 3 }] }];
      expect(discussionsContainNote(discussions, '2')).toBe(true);
    });

    it('matches numeric IDs against string noteId', () => {
      const discussions = [{ notes: [{ id: 123 }] }];
      expect(discussionsContainNote(discussions, '123')).toBe(true);
    });

    it('matches string IDs against string noteId', () => {
      const discussions = [{ notes: [{ id: '456' }] }];
      expect(discussionsContainNote(discussions, '456')).toBe(true);
    });

    it('returns false when no discussion contains the note', () => {
      const discussions = [{ notes: [{ id: 1 }] }, { notes: [{ id: 2 }] }];
      expect(discussionsContainNote(discussions, '99')).toBe(false);
    });

    it('returns false for empty discussions', () => {
      expect(discussionsContainNote([], '1')).toBe(false);
    });

    it('handles discussions without notes', () => {
      const discussions = [{ notes: null }, {}];
      expect(discussionsContainNote(discussions, '1')).toBe(false);
    });
  });
});
