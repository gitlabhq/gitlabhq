import {
  CONFLICT_TYPES,
  EDIT_RESOLVE_MODE,
  INTERACTIVE_RESOLVE_MODE,
} from '~/merge_conflicts/constants';
import * as getters from '~/merge_conflicts/store/getters';
import realState from '~/merge_conflicts/store/state';

describe('Merge Conflicts getters', () => {
  let state;

  beforeEach(() => {
    state = realState();
  });

  describe('getConflictsCount', () => {
    it('returns zero when there are no files', () => {
      state.conflictsData.files = [];

      expect(getters.getConflictsCount(state)).toBe(0);
    });

    it(`counts the number of sections in files of type ${CONFLICT_TYPES.TEXT}`, () => {
      state.conflictsData.files = [
        { sections: [{ conflict: true }], type: CONFLICT_TYPES.TEXT },
        { sections: [{ conflict: true }, { conflict: true }], type: CONFLICT_TYPES.TEXT },
      ];
      expect(getters.getConflictsCount(state)).toBe(3);
    });

    it(`counts the number of file in files  not of type ${CONFLICT_TYPES.TEXT}`, () => {
      state.conflictsData.files = [
        { sections: [{ conflict: true }], type: '' },
        { sections: [{ conflict: true }, { conflict: true }], type: '' },
      ];
      expect(getters.getConflictsCount(state)).toBe(2);
    });
  });

  describe('getConflictsCountText', () => {
    it('with one conflicts', () => {
      const getConflictsCount = 1;

      expect(getters.getConflictsCountText(state, { getConflictsCount })).toBe('1 conflict');
    });

    it('with more than one conflicts', () => {
      const getConflictsCount = 3;

      expect(getters.getConflictsCountText(state, { getConflictsCount })).toBe('3 conflicts');
    });
  });

  describe('isReadyToCommit', () => {
    it('return false when isSubmitting is true', () => {
      state.conflictsData.files = [];
      state.isSubmitting = true;
      state.conflictsData.commitMessage = 'foo';

      expect(getters.isReadyToCommit(state)).toBe(false);
    });

    it('returns false when has no commit message', () => {
      state.conflictsData.files = [];
      state.isSubmitting = false;
      state.conflictsData.commitMessage = '';

      expect(getters.isReadyToCommit(state)).toBe(false);
    });

    it('returns true when all conflicts are resolved and is not submitting and we have a commitMessage', () => {
      state.conflictsData.files = [
        {
          resolveMode: INTERACTIVE_RESOLVE_MODE,
          type: CONFLICT_TYPES.TEXT,
          sections: [{ conflict: true }],
          resolutionData: { foo: 'bar' },
        },
      ];
      state.isSubmitting = false;
      state.conflictsData.commitMessage = 'foo';

      expect(getters.isReadyToCommit(state)).toBe(true);
    });

    describe('unresolved', () => {
      it(`files with resolvedMode set to ${EDIT_RESOLVE_MODE} and empty count as unresolved`, () => {
        state.conflictsData.files = [
          { content: '', resolveMode: EDIT_RESOLVE_MODE },
          { content: 'foo' },
        ];
        state.isSubmitting = false;
        state.conflictsData.commitMessage = 'foo';

        expect(getters.isReadyToCommit(state)).toBe(false);
      });

      it(`in files with resolvedMode = ${INTERACTIVE_RESOLVE_MODE} we count resolvedConflicts vs unresolved ones`, () => {
        state.conflictsData.files = [
          {
            resolveMode: INTERACTIVE_RESOLVE_MODE,
            type: CONFLICT_TYPES.TEXT,
            sections: [{ conflict: true }],
            resolutionData: {},
          },
        ];
        state.isSubmitting = false;
        state.conflictsData.commitMessage = 'foo';

        expect(getters.isReadyToCommit(state)).toBe(false);
      });
    });
  });

  describe('getCommitButtonText', () => {
    it('when is submitting', () => {
      state.isSubmitting = true;
      expect(getters.getCommitButtonText(state)).toBe('Committing...');
    });

    it('when is not submitting', () => {
      expect(getters.getCommitButtonText(state)).toBe('Commit to source branch');
    });
  });

  describe('getCommitData', () => {
    it('returns commit data', () => {
      const baseFile = {
        new_path: 'new_path',
        old_path: 'new_path',
      };

      state.conflictsData.commitMessage = 'foo';
      state.conflictsData.files = [
        {
          ...baseFile,
          resolveMode: INTERACTIVE_RESOLVE_MODE,
          type: CONFLICT_TYPES.TEXT,
          sections: [{ conflict: true }],
          resolutionData: { bar: 'baz' },
        },
        {
          ...baseFile,
          resolveMode: EDIT_RESOLVE_MODE,
          type: CONFLICT_TYPES.TEXT,
          content: 'resolve_mode_content',
        },
        {
          ...baseFile,
          type: CONFLICT_TYPES.TEXT_EDITOR,
          content: 'text_editor_content',
        },
      ];

      expect(getters.getCommitData(state)).toStrictEqual({
        commit_message: 'foo',
        files: [
          { ...baseFile, sections: { bar: 'baz' } },
          { ...baseFile, content: 'resolve_mode_content' },
          { ...baseFile, content: 'text_editor_content' },
        ],
      });
    });
  });

  describe('fileTextTypePresent', () => {
    it(`returns true if there is a file with type ${CONFLICT_TYPES.TEXT}`, () => {
      state.conflictsData.files = [{ type: CONFLICT_TYPES.TEXT }];

      expect(getters.fileTextTypePresent(state)).toBe(true);
    });
    it(`returns false if there is no file with type ${CONFLICT_TYPES.TEXT}`, () => {
      state.conflictsData.files = [{ type: CONFLICT_TYPES.TEXT_EDITOR }];

      expect(getters.fileTextTypePresent(state)).toBe(false);
    });
  });

  describe('getFileIndex', () => {
    it(`returns the index of a file from it's blob path`, () => {
      const blobPath = 'blobPath/foo';
      state.conflictsData.files = [{ foo: 'bar' }, { baz: 'foo', blobPath }];

      expect(getters.getFileIndex(state)({ blobPath })).toBe(1);
    });
  });
});
