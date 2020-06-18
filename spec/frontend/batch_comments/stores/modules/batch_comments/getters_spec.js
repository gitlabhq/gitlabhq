import * as getters from '~/batch_comments/stores/modules/batch_comments/getters';

describe('Batch comments store getters', () => {
  describe('draftsForFile', () => {
    it('returns drafts for a file hash', () => {
      const state = {
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
      };

      expect(getters.draftsForFile(state)('filehash')).toEqual([
        {
          file_hash: 'filehash',
          comment: 'testing 123',
        },
      ]);
    });
  });
});
