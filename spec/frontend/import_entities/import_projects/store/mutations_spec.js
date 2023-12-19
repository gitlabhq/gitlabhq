import { STATUSES } from '~/import_entities/constants';
import * as types from '~/import_entities/import_projects/store/mutation_types';
import mutations from '~/import_entities/import_projects/store/mutations';
import getInitialState from '~/import_entities/import_projects/store/state';

describe('import_projects store mutations', () => {
  let state;

  const SOURCE_PROJECT = {
    id: 1,
    fullName: 'full/name',
    sanitizedName: 'name',
    providerLink: 'https://demo.link/full/name',
  };
  const IMPORTED_PROJECT = {
    name: 'demo',
    importSource: 'something',
    providerLink: 'https://demo.link/full/name',
    importStatus: 'status',
    fullName: 'fullName',
  };

  describe(`${types.SET_FILTER}`, () => {
    const NEW_VALUE = 'new-value';

    beforeEach(() => {
      state = {
        filter: { someField: 'some-value' },
        repositories: ['some', ' repositories'],
        pageInfo: {
          page: 1,
          startCursor: 'Y3Vyc30yOjI2',
          endCursor: 'Y3Vyc29yOjI1',
          hasNextPage: false,
        },
      };
      mutations[types.SET_FILTER](state, NEW_VALUE);
    });

    it('removes current repositories list', () => {
      expect(state.repositories.length).toBe(0);
    });

    it('resets pagintation', () => {
      expect(state.pageInfo.page).toBe(0);
      expect(state.pageInfo.startCursor).toBe(null);
      expect(state.pageInfo.endCursor).toBe(null);
      expect(state.pageInfo.hasNextPage).toBe(true);
    });

    it('merges filter updates', () => {
      const originalFilter = { ...state.filter };
      const anotherFilter = { anotherField: 'another-value' };
      mutations[types.SET_FILTER](state, anotherFilter);

      expect(state.filter).toStrictEqual({
        ...originalFilter,
        ...anotherFilter,
      });
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
    describe('with legacy response format', () => {
      describe('for imported projects', () => {
        const response = {
          importedProjects: [IMPORTED_PROJECT],
          providerRepos: [SOURCE_PROJECT],
        };

        it('adds importedProject to relevant provider repo', () => {
          state = getInitialState();

          mutations[types.RECEIVE_REPOS_SUCCESS](state, response);

          expect(state.repositories[0].importedProject).toStrictEqual(IMPORTED_PROJECT);
        });

        it('passes project to importProject', () => {
          state = getInitialState();

          mutations[types.RECEIVE_REPOS_SUCCESS](state, response);

          expect(IMPORTED_PROJECT).toStrictEqual(
            expect.objectContaining(state.repositories[0].importedProject),
          );
        });
      });

      describe('for importable projects', () => {
        beforeEach(() => {
          state = getInitialState();

          const response = {
            importedProjects: [],
            providerRepos: [SOURCE_PROJECT],
          };
          mutations[types.RECEIVE_REPOS_SUCCESS](state, response);
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
          state = getInitialState();
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

        state = getInitialState();

        mutations[types.RECEIVE_REPOS_SUCCESS](state, response);

        expect(state.isLoadingRepos).toBe(false);
      });
    });

    it('passes response as it is', () => {
      const response = [];
      state = getInitialState();

      mutations[types.RECEIVE_REPOS_SUCCESS](state, response);

      expect(state.repositories).toStrictEqual(response);
    });

    it('sets repos loading flag to false', () => {
      const response = [];

      state = getInitialState();

      mutations[types.RECEIVE_REPOS_SUCCESS](state, response);

      expect(state.isLoadingRepos).toBe(false);
    });
  });

  describe(`${types.RECEIVE_REPOS_ERROR}`, () => {
    it('sets repos loading flag to false', () => {
      state = getInitialState();

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
      expect(state.repositories[0].importedProject.importStatus).toBe(STATUSES.SCHEDULING);
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
      expect(state.repositories[0].importedProject.importStatus).toBe(
        IMPORTED_PROJECT.importStatus,
      );
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
      state = { repositories: [{ importSource: { id: REPO_ID }, importedProject: {} }] };

      mutations[types.RECEIVE_IMPORT_ERROR](state, REPO_ID);
    });

    it('sets status to failed', () => {
      expect(state.repositories[0].importedProject.importStatus).toBe(STATUSES.FAILED);
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

      expect(state.repositories[0].importedProject.importStatus).toBe(
        updatedProjects[0].importStatus,
      );
    });

    it('updates import stats of project', () => {
      const repoId = 1;
      state = {
        repositories: [
          { importedProject: { id: repoId, stats: {} }, importStatus: STATUSES.STARTED },
        ],
      };
      const newStats = {
        fetched: {
          label: 10,
        },
        imported: {
          label: 1,
        },
      };

      const updatedProjects = [
        {
          id: repoId,
          importStatus: STATUSES.FINISHED,
          stats: newStats,
        },
      ];

      mutations[types.RECEIVE_JOBS_SUCCESS](state, updatedProjects);

      expect(state.repositories[0].importedProject.stats).toStrictEqual(newStats);
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

  describe(`${types.SET_PAGE}`, () => {
    it('sets page number', () => {
      const NEW_PAGE = 4;
      state = { pageInfo: { page: 5 } };

      mutations[types.SET_PAGE](state, NEW_PAGE);
      expect(state.pageInfo.page).toBe(NEW_PAGE);
    });
  });

  describe(`${types.SET_PAGE_CURSORS}`, () => {
    it('sets page cursors', () => {
      const NEW_CURSORS = { startCursor: 'startCur', endCursor: 'endCur', hasNextPage: false };
      state = { pageInfo: { page: 1, startCursor: null, endCursor: null, hasNextPage: true } };

      mutations[types.SET_PAGE_CURSORS](state, NEW_CURSORS);
      expect(state.pageInfo).toEqual({ ...NEW_CURSORS, page: 1 });
    });
  });

  describe(`${types.SET_HAS_NEXT_PAGE}`, () => {
    it('sets hasNextPage in pageInfo', () => {
      const NEW_HAS_NEXT_PAGE = true;
      state = { pageInfo: { hasNextPage: false } };

      mutations[types.SET_HAS_NEXT_PAGE](state, NEW_HAS_NEXT_PAGE);
      expect(state.pageInfo.hasNextPage).toBe(NEW_HAS_NEXT_PAGE);
    });
  });

  describe(`${types.CANCEL_IMPORT_SUCCESS}`, () => {
    const payload = { repoId: 1 };

    beforeEach(() => {
      state = {
        repositories: [
          {
            importSource: { id: 1 },
            importedProject: { importStatus: STATUSES.NONE },
          },
        ],
      };
      mutations[types.CANCEL_IMPORT_SUCCESS](state, payload);
    });

    it('updates project status', () => {
      expect(state.repositories[0].importedProject.importStatus).toBe(STATUSES.CANCELED);
    });
  });
});
