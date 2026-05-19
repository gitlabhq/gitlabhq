import * as getters from '~/batch_comments/stores/modules/batch_comments/getters';

describe('Batch comments store getters', () => {
  describe('draftsForFile', () => {
    it('returns drafts for a file hash', () => {
      const state = {
        drafts: [
          { file_hash: 'filehash', comment: 'testing 123' },
          { file_hash: 'filehash2', comment: 'testing 1234' },
        ],
      };

      expect(getters.draftsForFile(state)('filehash')).toEqual([
        { file_hash: 'filehash', comment: 'testing 123' },
      ]);
    });
  });

  describe('draftsPerFileHashAndLine', () => {
    it('includes all drafts regardless of position', () => {
      const state = {
        drafts: [
          { file_hash: 'fh1', line_code: 'lc1', position: { head_sha: 'a' } },
          { file_hash: 'fh1', line_code: 'lc2', position: { head_sha: 'b' } },
        ],
      };

      const result = getters.draftsPerFileHashAndLine(state);
      expect(Object.keys(result.fh1)).toEqual(['lc1', 'lc2']);
    });
  });

  describe('shouldRenderDraftRow', () => {
    const buildArgs = (draftHeadSha, rootStateDiffs) => {
      const state = {
        drafts: [{ file_hash: 'fh1', line_code: 'lc1', position: { head_sha: draftHeadSha } }],
      };
      const rootState = { diffs: rootStateDiffs };
      const mockGetters = {
        draftsPerFileHashAndLine: getters.draftsPerFileHashAndLine(state),
      };
      return [state, mockGetters, rootState];
    };

    describe('on latest diff', () => {
      it('returns true even when head_sha differs', () => {
        const args = buildArgs('old', {
          latestDiff: true,
          diffFiles: [{ file_hash: 'fh1', diff_refs: { head_sha: 'new' } }],
        });

        expect(getters.shouldRenderDraftRow(...args)('fh1', { line_code: 'lc1' })).toBe(true);
      });

      it('returns true when head_sha matches', () => {
        const args = buildArgs('same', {
          latestDiff: true,
          diffFiles: [{ file_hash: 'fh1', diff_refs: { head_sha: 'same' } }],
        });

        expect(getters.shouldRenderDraftRow(...args)('fh1', { line_code: 'lc1' })).toBe(true);
      });
    });

    describe('on commit view', () => {
      it('returns true when head_sha matches commitId', () => {
        const args = buildArgs('commitA', {
          commit: { id: 'commitA' },
          diffFiles: [{ file_hash: 'fh1', diff_refs: { head_sha: 'commitA' } }],
        });

        expect(getters.shouldRenderDraftRow(...args)('fh1', { line_code: 'lc1' })).toBe(true);
      });

      it('returns false when head_sha does not match commitId', () => {
        const args = buildArgs('commitB', {
          commit: { id: 'commitA' },
          diffFiles: [{ file_hash: 'fh1', diff_refs: { head_sha: 'commitA' } }],
        });

        expect(getters.shouldRenderDraftRow(...args)('fh1', { line_code: 'lc1' })).toBe(false);
      });
    });

    describe('on older version', () => {
      it('returns true when head_sha matches diff file head_sha', () => {
        const args = buildArgs('vX', {
          latestDiff: false,
          diffFiles: [{ file_hash: 'fh1', diff_refs: { head_sha: 'vX' } }],
        });

        expect(getters.shouldRenderDraftRow(...args)('fh1', { line_code: 'lc1' })).toBe(true);
      });

      it('returns false when head_sha does not match diff file head_sha', () => {
        const args = buildArgs('vY', {
          latestDiff: false,
          diffFiles: [{ file_hash: 'fh1', diff_refs: { head_sha: 'vX' } }],
        });

        expect(getters.shouldRenderDraftRow(...args)('fh1', { line_code: 'lc1' })).toBe(false);
      });

      it('returns true when diff file has no diff_refs', () => {
        const args = buildArgs('any', {
          latestDiff: false,
          diffFiles: [{ file_hash: 'fh1' }],
        });

        expect(getters.shouldRenderDraftRow(...args)('fh1', { line_code: 'lc1' })).toBe(true);
      });
    });
  });

  describe('draftsForLine', () => {
    it('returns all text drafts on latest diff regardless of head_sha', () => {
      const draft = {
        file_hash: 'fh1',
        line_code: 'lc1',
        position: { position_type: 'text', head_sha: 'old' },
      };
      const state = { drafts: [draft] };
      const rootState = {
        diffs: {
          latestDiff: true,
          diffFiles: [{ file_hash: 'fh1', diff_refs: { head_sha: 'new' } }],
        },
      };
      const mockGetters = {
        draftsPerFileHashAndLine: getters.draftsPerFileHashAndLine(state),
      };

      expect(
        getters.draftsForLine(state, mockGetters, rootState)('fh1', { line_code: 'lc1' }),
      ).toEqual([draft]);
    });

    it('filters by commitId on commit view', () => {
      const matching = {
        file_hash: 'fh1',
        line_code: 'lc1',
        position: { position_type: 'text', head_sha: 'c1' },
      };
      const state = {
        drafts: [
          matching,
          {
            file_hash: 'fh1',
            line_code: 'lc1',
            position: { position_type: 'text', head_sha: 'c2' },
          },
        ],
      };
      const rootState = {
        diffs: {
          commit: { id: 'c1' },
          diffFiles: [{ file_hash: 'fh1', diff_refs: { head_sha: 'c1' } }],
        },
      };
      const mockGetters = {
        draftsPerFileHashAndLine: getters.draftsPerFileHashAndLine(state),
      };

      expect(
        getters.draftsForLine(state, mockGetters, rootState)('fh1', { line_code: 'lc1' }),
      ).toEqual([matching]);
    });

    it('filters by diff_refs.head_sha on older version', () => {
      const matching = {
        file_hash: 'fh1',
        line_code: 'lc1',
        position: { position_type: 'text', head_sha: 'v1' },
      };
      const state = {
        drafts: [
          matching,
          {
            file_hash: 'fh1',
            line_code: 'lc1',
            position: { position_type: 'text', head_sha: 'v2' },
          },
        ],
      };
      const rootState = {
        diffs: {
          latestDiff: false,
          diffFiles: [{ file_hash: 'fh1', diff_refs: { head_sha: 'v1' } }],
        },
      };
      const mockGetters = {
        draftsPerFileHashAndLine: getters.draftsPerFileHashAndLine(state),
      };

      expect(
        getters.draftsForLine(state, mockGetters, rootState)('fh1', { line_code: 'lc1' }),
      ).toEqual([matching]);
    });
  });
});
