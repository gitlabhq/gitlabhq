import state from '~/ide/stores/modules/branches/state';
import mutations from '~/ide/stores/modules/branches/mutations';
import * as types from '~/ide/stores/modules/branches/mutation_types';
import { branches } from '../../../mock_data';

describe('IDE branches mutations', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('REQUEST_BRANCHES', () => {
    it('sets loading to true', () => {
      mutations[types.REQUEST_BRANCHES](mockedState);

      expect(mockedState.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_BRANCHES_ERROR', () => {
    it('sets loading to false', () => {
      mutations[types.RECEIVE_BRANCHES_ERROR](mockedState);

      expect(mockedState.isLoading).toBe(false);
    });
  });

  describe('RECEIVE_BRANCHES_SUCCESS', () => {
    it('sets branches', () => {
      const expectedBranches = branches.map(branch => ({
        name: branch.name,
        committedDate: branch.commit.committed_date,
      }));

      mutations[types.RECEIVE_BRANCHES_SUCCESS](mockedState, branches);

      expect(mockedState.branches).toEqual(expectedBranches);
    });
  });

  describe('RESET_BRANCHES', () => {
    it('clears branches array', () => {
      mockedState.branches = ['test'];

      mutations[types.RESET_BRANCHES](mockedState);

      expect(mockedState.branches).toEqual([]);
    });
  });
});
