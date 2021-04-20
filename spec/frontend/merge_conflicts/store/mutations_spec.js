import { VIEW_TYPES } from '~/merge_conflicts/constants';
import * as types from '~/merge_conflicts/store/mutation_types';
import mutations from '~/merge_conflicts/store/mutations';
import realState from '~/merge_conflicts/store/state';

describe('Mutations merge conflicts store', () => {
  let mockState;

  beforeEach(() => {
    mockState = realState();
  });

  describe('SET_LOADING_STATE', () => {
    it('should set loading', () => {
      mutations[types.SET_LOADING_STATE](mockState, true);

      expect(mockState.isLoading).toBe(true);
    });
  });

  describe('SET_ERROR_STATE', () => {
    it('should set hasError', () => {
      mutations[types.SET_ERROR_STATE](mockState, true);

      expect(mockState.hasError).toBe(true);
    });
  });

  describe('SET_FAILED_REQUEST', () => {
    it('should set hasError and errorMessage', () => {
      const payload = 'message';
      mutations[types.SET_FAILED_REQUEST](mockState, payload);

      expect(mockState.hasError).toBe(true);
      expect(mockState.conflictsData.errorMessage).toBe(payload);
    });
  });

  describe('SET_VIEW_TYPE', () => {
    it('should set diffView', () => {
      mutations[types.SET_VIEW_TYPE](mockState, VIEW_TYPES.INLINE);

      expect(mockState.diffView).toBe(VIEW_TYPES.INLINE);
    });

    it(`if payload is ${VIEW_TYPES.PARALLEL} sets isParallel`, () => {
      mutations[types.SET_VIEW_TYPE](mockState, VIEW_TYPES.PARALLEL);

      expect(mockState.isParallel).toBe(true);
    });
  });

  describe('SET_SUBMIT_STATE', () => {
    it('should set isSubmitting', () => {
      mutations[types.SET_SUBMIT_STATE](mockState, true);

      expect(mockState.isSubmitting).toBe(true);
    });
  });

  describe('SET_CONFLICTS_DATA', () => {
    it('should set conflictsData', () => {
      mutations[types.SET_CONFLICTS_DATA](mockState, {
        files: [],
        commit_message: 'foo',
        source_branch: 'bar',
        target_branch: 'baz',
        commit_sha: '123456789',
      });

      expect(mockState.conflictsData).toStrictEqual({
        files: [],
        commitMessage: 'foo',
        sourceBranch: 'bar',
        targetBranch: 'baz',
        shortCommitSha: '1234567',
      });
    });
  });

  describe('UPDATE_CONFLICTS_DATA', () => {
    it('should update existing conflicts data', () => {
      const payload = { foo: 'bar' };
      mutations[types.UPDATE_CONFLICTS_DATA](mockState, payload);

      expect(mockState.conflictsData).toStrictEqual(payload);
    });
  });

  describe('UPDATE_FILE', () => {
    it('should update a file based on its index', () => {
      mockState.conflictsData.files = [{ foo: 'bar' }, { baz: 'bar' }];

      mutations[types.UPDATE_FILE](mockState, { file: { new: 'one' }, index: 1 });

      expect(mockState.conflictsData.files).toStrictEqual([{ foo: 'bar' }, { new: 'one' }]);
    });
  });
});
