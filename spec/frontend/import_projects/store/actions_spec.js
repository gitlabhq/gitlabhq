import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
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
} from '~/import_projects/store/mutation_types';
import {
  fetchRepos,
  fetchImport,
  receiveJobsSuccess,
  fetchJobs,
  clearJobsEtagPoll,
  stopJobsPolling,
} from '~/import_projects/store/actions';
import state from '~/import_projects/store/state';

describe('import_projects store actions', () => {
  let localState;
  const repos = [{ id: 1 }, { id: 2 }];
  const importPayload = { newName: 'newName', targetNamespace: 'targetNamespace', repo: { id: 1 } };

  beforeEach(() => {
    localState = state();
  });

  describe('fetchRepos', () => {
    let mock;
    const payload = { imported_projects: [{}], provider_repos: [{}], namespaces: [{}] };

    beforeEach(() => {
      localState.reposPath = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('dispatches stopJobsPolling actions and commits REQUEST_REPOS, RECEIVE_REPOS_SUCCESS mutations on a successful request', () => {
      mock.onGet(`${TEST_HOST}/endpoint.json`).reply(200, payload);

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
      mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);

      return testAction(
        fetchRepos,
        null,
        localState,
        [{ type: REQUEST_REPOS }, { type: RECEIVE_REPOS_ERROR }],
        [{ type: 'stopJobsPolling' }],
      );
    });

    describe('when filtered', () => {
      beforeEach(() => {
        localState.filter = 'filter';
      });

      it('fetches repos with filter applied', () => {
        mock.onGet(`${TEST_HOST}/endpoint.json?filter=filter`).reply(200, payload);

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
    });
  });

  describe('fetchImport', () => {
    let mock;

    beforeEach(() => {
      localState.importPath = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('commits REQUEST_IMPORT and REQUEST_IMPORT_SUCCESS mutations on a successful request', () => {
      const importedProject = { name: 'imported/project' };
      const importRepoId = importPayload.repo.id;
      mock.onPost(`${TEST_HOST}/endpoint.json`).reply(200, importedProject);

      return testAction(
        fetchImport,
        importPayload,
        localState,
        [
          { type: REQUEST_IMPORT, payload: importRepoId },
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

    it('commits REQUEST_IMPORT and RECEIVE_IMPORT_ERROR  on an unsuccessful request', () => {
      mock.onPost(`${TEST_HOST}/endpoint.json`).reply(500);

      return testAction(
        fetchImport,
        importPayload,
        localState,
        [
          { type: REQUEST_IMPORT, payload: importPayload.repo.id },
          { type: RECEIVE_IMPORT_ERROR, payload: importPayload.repo.id },
        ],
        [],
      );
    });
  });

  describe('receiveJobsSuccess', () => {
    it(`commits ${RECEIVE_JOBS_SUCCESS} mutation`, () => {
      return testAction(
        receiveJobsSuccess,
        repos,
        localState,
        [{ type: RECEIVE_JOBS_SUCCESS, payload: repos }],
        [],
      );
    });
  });

  describe('fetchJobs', () => {
    let mock;
    const updatedProjects = [{ name: 'imported/project' }, { name: 'provider/repo' }];

    beforeEach(() => {
      localState.jobsPath = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      stopJobsPolling();
      clearJobsEtagPoll();
    });

    afterEach(() => mock.restore());

    it('commits RECEIVE_JOBS_SUCCESS mutation on a successful request', async () => {
      mock.onGet(`${TEST_HOST}/endpoint.json`).reply(200, updatedProjects);

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
});
