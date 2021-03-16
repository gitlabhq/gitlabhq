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

  describe('sortedProjects', () => {
    it('should sort projects with variable branches', () => {
      const state = {
        projects: mockData.mockProjects,
      };

      expect(getters.sortedProjects(state)).toEqual(mockData.mockProjects.sort());
    });

    it('should provide a uniq list of projects', () => {
      const projects = ['_project_', '_project_', '_some_other_project'];
      const state = { projects };

      expect(getters.sortedProjects(state)).toEqual(projects.slice(1));
    });
  });
});
