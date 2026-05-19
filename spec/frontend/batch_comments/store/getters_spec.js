import { createTestingPinia } from '@pinia/testing';
import { useBatchComments } from '~/batch_comments/store';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useNotes } from '~/notes/store/legacy_notes';

describe('Batch comments store getters', () => {
  let store;
  let diffsStore;

  beforeEach(() => {
    createTestingPinia({ stubActions: false, plugins: [globalAccessorPlugin] });
    diffsStore = useLegacyDiffs();
    useNotes();
    store = useBatchComments();
  });

  describe('draftsForFile', () => {
    it('returns drafts for a file hash', () => {
      store.$patch({
        drafts: [
          {
            file_hash: 'filehash',
            comment: 'testing 123',
          },
          {
            file_hash: 'filehash2',
            comment: 'testing 1234',
          },
        ],
      });

      expect(store.draftsForFile('filehash')).toEqual([
        {
          file_hash: 'filehash',
          comment: 'testing 123',
        },
      ]);
    });
  });

  describe('draftsPerFileHashAndLine', () => {
    it('indexes all drafts by file_hash and line_code without filtering', () => {
      store.$patch({
        drafts: [
          {
            file_hash: 'hash1',
            line_code: 'line1',
            position: { position_type: 'text', head_sha: 'commit1' },
          },
          {
            file_hash: 'hash1',
            line_code: 'line2',
            position: { position_type: 'text', head_sha: 'commit2' },
          },
        ],
      });

      expect(Object.keys(store.draftsPerFileHashAndLine.hash1)).toEqual(['line1', 'line2']);
    });
  });

  describe('shouldRenderDraftRow', () => {
    describe('on latest diff', () => {
      it('returns true even when head_sha differs', () => {
        diffsStore.$patch({
          latestDiff: true,
          diffFiles: [{ file_hash: 'hash1', diff_refs: { head_sha: 'new_head' } }],
        });

        store.$patch({
          drafts: [
            {
              file_hash: 'hash1',
              line_code: 'lc1',
              position: { position_type: 'text', head_sha: 'old_head' },
            },
          ],
        });

        expect(store.shouldRenderDraftRow('hash1', { line_code: 'lc1' })).toBe(true);
      });

      it('returns true when head_sha matches', () => {
        diffsStore.$patch({
          latestDiff: true,
          diffFiles: [{ file_hash: 'hash1', diff_refs: { head_sha: 'same' } }],
        });

        store.$patch({
          drafts: [
            {
              file_hash: 'hash1',
              line_code: 'lc1',
              position: { position_type: 'text', head_sha: 'same' },
            },
          ],
        });

        expect(store.shouldRenderDraftRow('hash1', { line_code: 'lc1' })).toBe(true);
      });
    });

    describe('on commit view', () => {
      it('returns true when head_sha matches commitId', () => {
        diffsStore.$patch({
          commit: { id: 'commitA' },
          diffFiles: [{ file_hash: 'hash1', diff_refs: { head_sha: 'commitA' } }],
        });

        store.$patch({
          drafts: [
            {
              file_hash: 'hash1',
              line_code: 'lc1',
              position: { position_type: 'text', head_sha: 'commitA' },
            },
          ],
        });

        expect(store.shouldRenderDraftRow('hash1', { line_code: 'lc1' })).toBe(true);
      });

      it('returns false when head_sha does not match commitId', () => {
        diffsStore.$patch({
          commit: { id: 'commitA' },
          diffFiles: [{ file_hash: 'hash1', diff_refs: { head_sha: 'commitA' } }],
        });

        store.$patch({
          drafts: [
            {
              file_hash: 'hash1',
              line_code: 'lc1',
              position: { position_type: 'text', head_sha: 'commitB' },
            },
          ],
        });

        expect(store.shouldRenderDraftRow('hash1', { line_code: 'lc1' })).toBe(false);
      });
    });

    describe('on older version', () => {
      it('returns true when head_sha matches diff file head_sha', () => {
        diffsStore.$patch({
          latestDiff: false,
          diffFiles: [{ file_hash: 'hash1', diff_refs: { head_sha: 'versionX' } }],
        });

        store.$patch({
          drafts: [
            {
              file_hash: 'hash1',
              line_code: 'lc1',
              position: { position_type: 'text', head_sha: 'versionX' },
            },
          ],
        });

        expect(store.shouldRenderDraftRow('hash1', { line_code: 'lc1' })).toBe(true);
      });

      it('returns false when head_sha does not match diff file head_sha', () => {
        diffsStore.$patch({
          latestDiff: false,
          diffFiles: [{ file_hash: 'hash1', diff_refs: { head_sha: 'versionX' } }],
        });

        store.$patch({
          drafts: [
            {
              file_hash: 'hash1',
              line_code: 'lc1',
              position: { position_type: 'text', head_sha: 'versionY' },
            },
          ],
        });

        expect(store.shouldRenderDraftRow('hash1', { line_code: 'lc1' })).toBe(false);
      });

      it('returns true when diff file has no diff_refs', () => {
        diffsStore.$patch({
          latestDiff: false,
          diffFiles: [{ file_hash: 'hash1' }],
        });

        store.$patch({
          drafts: [
            {
              file_hash: 'hash1',
              line_code: 'lc1',
              position: { position_type: 'text', head_sha: 'any' },
            },
          ],
        });

        expect(store.shouldRenderDraftRow('hash1', { line_code: 'lc1' })).toBe(true);
      });
    });
  });

  describe('draftsForLine', () => {
    it('returns all text drafts on latest diff regardless of head_sha', () => {
      diffsStore.$patch({
        latestDiff: true,
        diffFiles: [{ file_hash: 'hash1', diff_refs: { head_sha: 'new_head' } }],
      });

      store.$patch({
        drafts: [
          {
            file_hash: 'hash1',
            line_code: 'lc1',
            position: { position_type: 'text', head_sha: 'old_head' },
          },
        ],
      });

      expect(store.draftsForLine('hash1', { line_code: 'lc1' })).toEqual([
        {
          file_hash: 'hash1',
          line_code: 'lc1',
          position: { position_type: 'text', head_sha: 'old_head' },
        },
      ]);
    });

    it('filters by commitId on commit view', () => {
      diffsStore.$patch({
        commit: { id: 'c1' },
        diffFiles: [{ file_hash: 'hash1', diff_refs: { head_sha: 'c1' } }],
      });

      store.$patch({
        drafts: [
          {
            file_hash: 'hash1',
            line_code: 'lc1',
            position: { position_type: 'text', head_sha: 'c1' },
          },
          {
            file_hash: 'hash1',
            line_code: 'lc1',
            position: { position_type: 'text', head_sha: 'c2' },
          },
        ],
      });

      const result = store.draftsForLine('hash1', { line_code: 'lc1' });
      expect(result).toHaveLength(1);
      expect(result[0].position.head_sha).toBe('c1');
    });

    it('filters by diff_refs.head_sha on older version', () => {
      diffsStore.$patch({
        latestDiff: false,
        diffFiles: [{ file_hash: 'hash1', diff_refs: { head_sha: 'v1' } }],
      });

      store.$patch({
        drafts: [
          {
            file_hash: 'hash1',
            line_code: 'lc1',
            position: { position_type: 'text', head_sha: 'v1' },
          },
          {
            file_hash: 'hash1',
            line_code: 'lc1',
            position: { position_type: 'text', head_sha: 'v2' },
          },
        ],
      });

      const result = store.draftsForLine('hash1', { line_code: 'lc1' });
      expect(result).toHaveLength(1);
      expect(result[0].position.head_sha).toBe('v1');
    });
  });
});
