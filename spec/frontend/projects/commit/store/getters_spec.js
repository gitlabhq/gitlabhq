import * as getters from '~/projects/commit/store/getters';
import mockData from '../mock_data';

describe('Commit form modal getters', () => {
  describe('joinedBranches', () => {
    it('should join fetched branches with variable branches', () => {
      const state = {
        branches: mockData.mockBranches,
      };

      expect(getters.joinedBranches(state)).toEqual(mockData.mockBranches.sort());
    });

    it('should provide a uniq list of branches', () => {
      const branches = ['_branch_', '_branch_', '_different_branch'];
      const state = { branches };

      expect(getters.joinedBranches(state)).toEqual(branches.slice(1));
    });
  });
});
