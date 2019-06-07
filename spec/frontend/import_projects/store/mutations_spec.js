import * as types from '~/import_projects/store/mutation_types';
import mutations from '~/import_projects/store/mutations';

describe('import_projects store mutations', () => {
  describe(`${types.RECEIVE_IMPORT_SUCCESS}`, () => {
    it('removes repoId from reposBeingImported and providerRepos, adds to importedProjects', () => {
      const repoId = 1;
      const state = {
        reposBeingImported: [repoId],
        providerRepos: [{ id: repoId }],
        importedProjects: [],
      };
      const importedProject = { id: repoId };

      mutations[types.RECEIVE_IMPORT_SUCCESS](state, { importedProject, repoId });

      expect(state.reposBeingImported.includes(repoId)).toBe(false);
      expect(state.providerRepos.some(repo => repo.id === repoId)).toBe(false);
      expect(state.importedProjects.some(repo => repo.id === repoId)).toBe(true);
    });
  });

  describe(`${types.RECEIVE_JOBS_SUCCESS}`, () => {
    it('updates importStatus of existing importedProjects', () => {
      const repoId = 1;
      const state = { importedProjects: [{ id: repoId, importStatus: 'started' }] };
      const updatedProjects = [{ id: repoId, importStatus: 'finished' }];

      mutations[types.RECEIVE_JOBS_SUCCESS](state, updatedProjects);

      expect(state.importedProjects[0].importStatus).toBe(updatedProjects[0].importStatus);
    });
  });
});
