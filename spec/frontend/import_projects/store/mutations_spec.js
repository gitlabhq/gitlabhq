import * as types from '~/import_projects/store/mutation_types';
import mutations from '~/import_projects/store/mutations';
import { STATUSES } from '~/import_projects/constants';

describe('import_projects store mutations', () => {
  let state;
  const SOURCE_PROJECT = {
    id: 1,
    full_name: 'full/name',
    sanitized_name: 'name',
    provider_link: 'https://demo.link/full/name',
  };
  const IMPORTED_PROJECT = {
    name: 'demo',
    importSource: 'something',
    providerLink: 'custom-link',
    importStatus: 'status',
    fullName: 'fullName',
  };

  describe(`${types.SET_FILTER}`, () => {
    it('overwrites current filter value', () => {
      state = { filter: 'some-value' };
      const NEW_VALUE = 'new-value';

      mutations[types.SET_FILTER](state, NEW_VALUE);

      expect(state.filter).toBe(NEW_VALUE);
    });
  });

  describe(`${types.REQUEST_REPOS}`, () => {
    it('sets repos loading flag to true', () => {
      state = {};

      mutations[types.REQUEST_REPOS](state);

      expect(state.isLoadingRepos).toBe(true);
    });
  });

  describe(`${types.RECEIVE_REPOS_SUCCESS}`, () => {
    describe('for imported projects', () => {
      const response = {
        importedProjects: [IMPORTED_PROJECT],
        providerRepos: [],
      };

      it('picks import status from response', () => {
        state = {};

        mutations[types.RECEIVE_REPOS_SUCCESS](state, response);

        expect(state.repositories[0].importStatus).toBe(IMPORTED_PROJECT.importStatus);
      });

      it('recreates importSource from response', () => {
        state = {};

        mutations[types.RECEIVE_REPOS_SUCCESS](state, response);

        expect(state.repositories[0].importSource).toStrictEqual(
          expect.objectContaining({
            fullName: IMPORTED_PROJECT.importSource,
            sanitizedName: IMPORTED_PROJECT.name,
            providerLink: IMPORTED_PROJECT.providerLink,
          }),
        );
      });

      it('passes project to importProject', () => {
        state = {};

        mutations[types.RECEIVE_REPOS_SUCCESS](state, response);

        expect(IMPORTED_PROJECT).toStrictEqual(
          expect.objectContaining(state.repositories[0].importedProject),
        );
      });
    });

    describe('for importable projects', () => {
      beforeEach(() => {
        state = {};
        const response = {
          importedProjects: [],
          providerRepos: [SOURCE_PROJECT],
        };
        mutations[types.RECEIVE_REPOS_SUCCESS](state, response);
      });

      it('sets import status to none', () => {
        expect(state.repositories[0].importStatus).toBe(STATUSES.NONE);
      });

      it('sets importSource to project', () => {
        expect(state.repositories[0].importSource).toBe(SOURCE_PROJECT);
      });
    });

    describe('for incompatible projects', () => {
      const response = {
        importedProjects: [],
        providerRepos: [],
        incompatibleRepos: [SOURCE_PROJECT],
      };

      beforeEach(() => {
        state = {};
        mutations[types.RECEIVE_REPOS_SUCCESS](state, response);
      });

      it('sets incompatible flag', () => {
        expect(state.repositories[0].importSource.incompatible).toBe(true);
      });

      it('sets importSource to project', () => {
        expect(state.repositories[0].importSource).toStrictEqual(
          expect.objectContaining(SOURCE_PROJECT),
        );
      });
    });

    it('sets repos loading flag to false', () => {
      const response = {
        importedProjects: [],
        providerRepos: [],
      };
      state = {};

      mutations[types.RECEIVE_REPOS_SUCCESS](state, response);

      expect(state.isLoadingRepos).toBe(false);
    });
  });

  describe(`${types.RECEIVE_REPOS_ERROR}`, () => {
    it('sets repos loading flag to false', () => {
      state = {};

      mutations[types.RECEIVE_REPOS_ERROR](state);

      expect(state.isLoadingRepos).toBe(false);
    });
  });

  describe(`${types.REQUEST_IMPORT}`, () => {
    beforeEach(() => {
      const REPO_ID = 1;
      const importTarget = { targetNamespace: 'ns', newName: 'name ' };
      state = { repositories: [{ importSource: { id: REPO_ID } }] };

      mutations[types.REQUEST_IMPORT](state, { repoId: REPO_ID, importTarget });
    });

    it(`sets status to ${STATUSES.SCHEDULING}`, () => {
      expect(state.repositories[0].importStatus).toBe(STATUSES.SCHEDULING);
    });
  });

  describe(`${types.RECEIVE_IMPORT_SUCCESS}`, () => {
    beforeEach(() => {
      const REPO_ID = 1;
      state = { repositories: [{ importSource: { id: REPO_ID } }] };

      mutations[types.RECEIVE_IMPORT_SUCCESS](state, {
        repoId: REPO_ID,
        importedProject: IMPORTED_PROJECT,
      });
    });

    it('sets import status', () => {
      expect(state.repositories[0].importStatus).toBe(IMPORTED_PROJECT.importStatus);
    });

    it('sets imported project', () => {
      expect(IMPORTED_PROJECT).toStrictEqual(
        expect.objectContaining(state.repositories[0].importedProject),
      );
    });
  });

  describe(`${types.RECEIVE_IMPORT_ERROR}`, () => {
    beforeEach(() => {
      const REPO_ID = 1;
      state = { repositories: [{ importSource: { id: REPO_ID } }] };

      mutations[types.RECEIVE_IMPORT_ERROR](state, REPO_ID);
    });

    it(`resets import status to ${STATUSES.NONE}`, () => {
      expect(state.repositories[0].importStatus).toBe(STATUSES.NONE);
    });
  });

  describe(`${types.RECEIVE_JOBS_SUCCESS}`, () => {
    it('updates import status of existing project', () => {
      const repoId = 1;
      state = {
        repositories: [{ importedProject: { id: repoId }, importStatus: STATUSES.STARTED }],
      };
      const updatedProjects = [{ id: repoId, importStatus: STATUSES.FINISHED }];

      mutations[types.RECEIVE_JOBS_SUCCESS](state, updatedProjects);

      expect(state.repositories[0].importStatus).toBe(updatedProjects[0].importStatus);
    });
  });

  describe(`${types.REQUEST_NAMESPACES}`, () => {
    it('sets namespaces loading flag to true', () => {
      state = {};

      mutations[types.REQUEST_NAMESPACES](state);

      expect(state.isLoadingNamespaces).toBe(true);
    });
  });

  describe(`${types.RECEIVE_NAMESPACES_SUCCESS}`, () => {
    const response = [{ fullPath: 'some/path' }];

    beforeEach(() => {
      state = {};
      mutations[types.RECEIVE_NAMESPACES_SUCCESS](state, response);
    });

    it('stores namespaces to state', () => {
      expect(state.namespaces).toStrictEqual(response);
    });

    it('sets namespaces loading flag to false', () => {
      expect(state.isLoadingNamespaces).toBe(false);
    });
  });

  describe(`${types.RECEIVE_NAMESPACES_ERROR}`, () => {
    it('sets namespaces loading flag to false', () => {
      state = {};

      mutations[types.RECEIVE_NAMESPACES_ERROR](state);

      expect(state.isLoadingNamespaces).toBe(false);
    });
  });

  describe(`${types.SET_IMPORT_TARGET}`, () => {
    const PROJECT = {
      id: 2,
      sanitizedName: 'sanitizedName',
    };

    it('stores custom target if it differs from defaults', () => {
      state = { customImportTargets: {}, repositories: [{ importSource: PROJECT }] };
      const importTarget = { targetNamespace: 'ns', newName: 'name ' };

      mutations[types.SET_IMPORT_TARGET](state, { repoId: PROJECT.id, importTarget });
      expect(state.customImportTargets[PROJECT.id]).toBe(importTarget);
    });

    it('removes custom target if it is equal to defaults', () => {
      const importTarget = { targetNamespace: 'ns', newName: 'name ' };
      state = {
        defaultTargetNamespace: 'default',
        customImportTargets: {
          [PROJECT.id]: importTarget,
        },
        repositories: [{ importSource: PROJECT }],
      };

      mutations[types.SET_IMPORT_TARGET](state, {
        repoId: PROJECT.id,
        importTarget: {
          targetNamespace: state.defaultTargetNamespace,
          newName: PROJECT.sanitizedName,
        },
      });

      expect(state.customImportTargets[SOURCE_PROJECT.id]).toBeUndefined();
    });
  });
});
