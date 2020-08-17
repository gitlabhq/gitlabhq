import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  REQUEST_REPOS,
  RECEIVE_REPOS_SUCCESS,
  RECEIVE_REPOS_ERROR,
  REQUEST_IMPORT,
  RECEIVE_IMPORT_SUCCESS,
  RECEIVE_IMPORT_ERROR,
  RECEIVE_JOBS_SUCCESS,
  REQUEST_NAMESPACES,
  RECEIVE_NAMESPACES_SUCCESS,
  RECEIVE_NAMESPACES_ERROR,
  SET_PAGE,
} from '~/import_projects/store/mutation_types';
import actionsFactory from '~/import_projects/store/actions';
import { getImportTarget } from '~/import_projects/store/getters';
import state from '~/import_projects/store/state';
import { STATUSES } from '~/import_projects/constants';

jest.mock('~/flash');

const MOCK_ENDPOINT = `${TEST_HOST}/endpoint.json`;
const endpoints = {
  reposPath: MOCK_ENDPOINT,
  importPath: MOCK_ENDPOINT,
  jobsPath: MOCK_ENDPOINT,
  namespacesPath: MOCK_ENDPOINT,
};

const {
  clearJobsEtagPoll,
  stopJobsPolling,
  importAll,
  fetchRepos,
  fetchImport,
  fetchJobs,
  fetchNamespaces,
  setPage,
} = actionsFactory({
  endpoints,
});

describe('import_projects store actions', () => {
  let localState;
  const importRepoId = 1;
  const otherImportRepoId = 2;
  const defaultTargetNamespace = 'default';
  const sanitizedName = 'sanitizedName';
  const defaultImportTarget = { newName: sanitizedName, targetNamespace: defaultTargetNamespace };

  beforeEach(() => {
    localState = {
      ...state(),
      defaultTargetNamespace,
      repositories: [
        { importSource: { id: importRepoId, sanitizedName }, importStatus: STATUSES.NONE },
        {
          importSource: { id: otherImportRepoId, sanitizedName: 's2' },
          importStatus: STATUSES.NONE,
        },
        {
          importSource: { id: 3, sanitizedName: 's3', incompatible: true },
          importStatus: STATUSES.NONE,
        },
      ],
    };

    localState.getImportTarget = getImportTarget(localState);
  });

  describe('fetchRepos', () => {
    let mock;
    const payload = { imported_projects: [{}], provider_repos: [{}] };

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('dispatches stopJobsPolling actions and commits REQUEST_REPOS, RECEIVE_REPOS_SUCCESS mutations on a successful request', () => {
      mock.onGet(MOCK_ENDPOINT).reply(200, payload);

      return testAction(
        fetchRepos,
        null,
        localState,
        [
          { type: REQUEST_REPOS },
          {
            type: RECEIVE_REPOS_SUCCESS,
            payload: convertObjectPropsToCamelCase(payload, { deep: true }),
          },
        ],
        [{ type: 'stopJobsPolling' }, { type: 'fetchJobs' }],
      );
    });

    it('dispatches stopJobsPolling action and commits REQUEST_REPOS, RECEIVE_REPOS_ERROR mutations on an unsuccessful request', () => {
      mock.onGet(MOCK_ENDPOINT).reply(500);

      return testAction(
        fetchRepos,
        null,
        localState,
        [{ type: REQUEST_REPOS }, { type: RECEIVE_REPOS_ERROR }],
        [{ type: 'stopJobsPolling' }],
      );
    });

    describe('when pagination is enabled', () => {
      it('includes page in url query params', async () => {
        const { fetchRepos: fetchReposWithPagination } = actionsFactory({
          endpoints,
          hasPagination: true,
        });

        let requestedUrl;
        mock.onGet().reply(config => {
          requestedUrl = config.url;
          return [200, payload];
        });

        await testAction(
          fetchReposWithPagination,
          null,
          localState,
          expect.any(Array),
          expect.any(Array),
        );

        expect(requestedUrl).toBe(`${MOCK_ENDPOINT}?page=${localState.pageInfo.page}`);
      });
    });

    describe('when filtered', () => {
      it('fetches repos with filter applied', () => {
        mock.onGet(`${TEST_HOST}/endpoint.json?filter=filter`).reply(200, payload);

        return testAction(
          fetchRepos,
          null,
          { ...localState, filter: 'filter' },
          [
            { type: REQUEST_REPOS },
            {
              type: RECEIVE_REPOS_SUCCESS,
              payload: convertObjectPropsToCamelCase(payload, { deep: true }),
            },
          ],
          [{ type: 'stopJobsPolling' }, { type: 'fetchJobs' }],
        );
      });
    });
  });

  describe('fetchImport', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('commits REQUEST_IMPORT and REQUEST_IMPORT_SUCCESS mutations on a successful request', () => {
      const importedProject = { name: 'imported/project' };
      mock.onPost(MOCK_ENDPOINT).reply(200, importedProject);

      return testAction(
        fetchImport,
        importRepoId,
        localState,
        [
          {
            type: REQUEST_IMPORT,
            payload: { repoId: importRepoId, importTarget: defaultImportTarget },
          },
          {
            type: RECEIVE_IMPORT_SUCCESS,
            payload: {
              importedProject: convertObjectPropsToCamelCase(importedProject, { deep: true }),
              repoId: importRepoId,
            },
          },
        ],
        [],
      );
    });

    it('commits REQUEST_IMPORT and RECEIVE_IMPORT_ERROR and shows generic error message on an unsuccessful request', async () => {
      mock.onPost(MOCK_ENDPOINT).reply(500);

      await testAction(
        fetchImport,
        importRepoId,
        localState,
        [
          {
            type: REQUEST_IMPORT,
            payload: { repoId: importRepoId, importTarget: defaultImportTarget },
          },
          { type: RECEIVE_IMPORT_ERROR, payload: importRepoId },
        ],
        [],
      );

      expect(createFlash).toHaveBeenCalledWith('Importing the project failed');
    });

    it('commits REQUEST_IMPORT and RECEIVE_IMPORT_ERROR and shows detailed error message on an unsuccessful request with errors fields in response', async () => {
      const ERROR_MESSAGE = 'dummy';
      mock.onPost(MOCK_ENDPOINT).reply(500, { errors: ERROR_MESSAGE });

      await testAction(
        fetchImport,
        importRepoId,
        localState,
        [
          {
            type: REQUEST_IMPORT,
            payload: { repoId: importRepoId, importTarget: defaultImportTarget },
          },
          { type: RECEIVE_IMPORT_ERROR, payload: importRepoId },
        ],
        [],
      );

      expect(createFlash).toHaveBeenCalledWith(`Importing the project failed: ${ERROR_MESSAGE}`);
    });
  });

  describe('fetchJobs', () => {
    let mock;
    const updatedProjects = [{ name: 'imported/project' }, { name: 'provider/repo' }];

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      stopJobsPolling();
      clearJobsEtagPoll();
    });

    afterEach(() => mock.restore());

    it('commits RECEIVE_JOBS_SUCCESS mutation on a successful request', async () => {
      mock.onGet(MOCK_ENDPOINT).reply(200, updatedProjects);

      await testAction(
        fetchJobs,
        null,
        localState,
        [
          {
            type: RECEIVE_JOBS_SUCCESS,
            payload: convertObjectPropsToCamelCase(updatedProjects, { deep: true }),
          },
        ],
        [],
      );
    });

    describe('when filtered', () => {
      beforeEach(() => {
        localState.filter = 'filter';
      });

      it('fetches realtime changes with filter applied', () => {
        mock.onGet(`${TEST_HOST}/endpoint.json?filter=filter`).reply(200, updatedProjects);

        return testAction(
          fetchJobs,
          null,
          localState,
          [
            {
              type: RECEIVE_JOBS_SUCCESS,
              payload: convertObjectPropsToCamelCase(updatedProjects, { deep: true }),
            },
          ],
          [],
        );
      });
    });
  });

  describe('fetchNamespaces', () => {
    let mock;
    const namespaces = [{ full_name: 'test/ns1' }, { full_name: 'test_ns2' }];

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('commits REQUEST_NAMESPACES and RECEIVE_NAMESPACES_SUCCESS on success', async () => {
      mock.onGet(MOCK_ENDPOINT).reply(200, namespaces);

      await testAction(
        fetchNamespaces,
        null,
        localState,
        [
          { type: REQUEST_NAMESPACES },
          {
            type: RECEIVE_NAMESPACES_SUCCESS,
            payload: convertObjectPropsToCamelCase(namespaces, { deep: true }),
          },
        ],
        [],
      );
    });

    it('commits REQUEST_NAMESPACES and RECEIVE_NAMESPACES_ERROR and shows generic error message on an unsuccessful request', async () => {
      mock.onGet(MOCK_ENDPOINT).reply(500);

      await testAction(
        fetchNamespaces,
        null,
        localState,
        [{ type: REQUEST_NAMESPACES }, { type: RECEIVE_NAMESPACES_ERROR }],
        [],
      );

      expect(createFlash).toHaveBeenCalledWith('Requesting namespaces failed');
    });
  });

  describe('importAll', () => {
    it('dispatches multiple fetchImport actions', async () => {
      await testAction(
        importAll,
        null,
        localState,
        [],
        [
          { type: 'fetchImport', payload: importRepoId },
          { type: 'fetchImport', payload: otherImportRepoId },
        ],
      );
    });

    describe('setPage', () => {
      it('dispatches fetchRepos and commits setPage when page number differs from current one', async () => {
        await testAction(
          setPage,
          2,
          { ...localState, pageInfo: { page: 1 } },
          [{ type: SET_PAGE, payload: 2 }],
          [{ type: 'fetchRepos' }],
        );
      });

      it('does not perform any action if page equals to current one', async () => {
        await testAction(setPage, 2, { ...localState, pageInfo: { page: 2 } }, [], []);
      });
    });
  });
});
