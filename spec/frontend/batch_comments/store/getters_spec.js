import { createTestingPinia } from '@pinia/testing';
import { useBatchComments } from '~/batch_comments/store';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useNotes } from '~/notes/store/legacy_notes';

describe('Batch comments store getters', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false, plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
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
});
