import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  SET_INITIAL_DATA,
  REQUEST_REPOS,
  RECEIVE_REPOS_SUCCESS,
  RECEIVE_REPOS_ERROR,
  REQUEST_IMPORT,
  RECEIVE_IMPORT_SUCCESS,
  RECEIVE_IMPORT_ERROR,
  RECEIVE_JOBS_SUCCESS,
} from '~/import_projects/store/mutation_types';
import {
  setInitialData,
  requestRepos,
  receiveReposSuccess,
  receiveReposError,
  fetchRepos,
  requestImport,
  receiveImportSuccess,
  receiveImportError,
  fetchImport,
  receiveJobsSuccess,
  fetchJobs,
  clearJobsEtagPoll,
  stopJobsPolling,
} from '~/import_projects/store/actions';
import state from '~/import_projects/store/state';

describe('import_projects store actions', () => {
  let localState;
  const repoId = 1;
  const repos = [{ id: 1 }, { id: 2 }];
  const importPayload = { newName: 'newName', targetNamespace: 'targetNamespace', repo: { id: 1 } };

  beforeEach(() => {
    localState = state();
  });

  describe('setInitialData', () => {
    it(`commits ${SET_INITIAL_DATA} mutation`, done => {
      const initialData = {
        reposPath: 'reposPath',
        provider: 'provider',
        jobsPath: 'jobsPath',
        importPath: 'impapp/assets/javascripts/vue_shared/components/select2_select.vueortPath',
        defaultTargetNamespace: 'defaultTargetNamespace',
        ciCdOnly: 'ciCdOnly',
        canSelectNamespace: 'canSelectNamespace',
      };

      testAction(
        setInitialData,
        initialData,
        localState,
        [{ type: SET_INITIAL_DATA, payload: initialData }],
        [],
        done,
      );
    });
  });

  describe('requestRepos', () => {
    it(`requestRepos commits ${REQUEST_REPOS} mutation`, done => {
      testAction(
        requestRepos,
        null,
        localState,
        [{ type: REQUEST_REPOS, payload: null }],
        [],
        done,
      );
    });
  });

  describe('receiveReposSuccess', () => {
    it(`commits ${RECEIVE_REPOS_SUCCESS} mutation`, done => {
      testAction(
        receiveReposSuccess,
        repos,
        localState,
        [{ type: RECEIVE_REPOS_SUCCESS, payload: repos }],
        [],
        done,
      );
    });
  });

  describe('receiveReposError', () => {
    it(`commits ${RECEIVE_REPOS_ERROR} mutation`, done => {
      testAction(receiveReposError, repos, localState, [{ type: RECEIVE_REPOS_ERROR }], [], done);
    });
  });

  describe('fetchRepos', () => {
    let mock;
    const payload = { imported_projects: [{}], provider_repos: [{}], namespaces: [{}] };

    beforeEach(() => {
      localState.reposPath = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('dispatches stopJobsPolling, requestRepos and receiveReposSuccess actions on a successful request', done => {
      mock.onGet(`${TEST_HOST}/endpoint.json`).reply(200, payload);

      testAction(
        fetchRepos,
        null,
        localState,
        [],
        [
          { type: 'stopJobsPolling' },
          { type: 'requestRepos' },
          {
            type: 'receiveReposSuccess',
            payload: convertObjectPropsToCamelCase(payload, { deep: true }),
          },
          {
            type: 'fetchJobs',
          },
        ],
        done,
      );
    });

    it('dispatches stopJobsPolling, requestRepos and receiveReposError actions on an unsuccessful request', done => {
      mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);

      testAction(
        fetchRepos,
        null,
        localState,
        [],
        [{ type: 'stopJobsPolling' }, { type: 'requestRepos' }, { type: 'receiveReposError' }],
        done,
      );
    });

    describe('when filtered', () => {
      beforeEach(() => {
        localState.filter = 'filter';
      });

      it('fetches repos with filter applied', done => {
        mock.onGet(`${TEST_HOST}/endpoint.json?filter=filter`).reply(200, payload);

        testAction(
          fetchRepos,
          null,
          localState,
          [],
          [
            { type: 'stopJobsPolling' },
            { type: 'requestRepos' },
            {
              type: 'receiveReposSuccess',
              payload: convertObjectPropsToCamelCase(payload, { deep: true }),
            },
            {
              type: 'fetchJobs',
            },
          ],
          done,
        );
      });
    });
  });

  describe('requestImport', () => {
    it(`commits ${REQUEST_IMPORT} mutation`, done => {
      testAction(
        requestImport,
        repoId,
        localState,
        [{ type: REQUEST_IMPORT, payload: repoId }],
        [],
        done,
      );
    });
  });

  describe('receiveImportSuccess', () => {
    it(`commits ${RECEIVE_IMPORT_SUCCESS} mutation`, done => {
      const payload = { importedProject: { name: 'imported/project' }, repoId: 2 };

      testAction(
        receiveImportSuccess,
        payload,
        localState,
        [{ type: RECEIVE_IMPORT_SUCCESS, payload }],
        [],
        done,
      );
    });
  });

  describe('receiveImportError', () => {
    it(`commits ${RECEIVE_IMPORT_ERROR} mutation`, done => {
      testAction(
        receiveImportError,
        repoId,
        localState,
        [{ type: RECEIVE_IMPORT_ERROR, payload: repoId }],
        [],
        done,
      );
    });
  });

  describe('fetchImport', () => {
    let mock;

    beforeEach(() => {
      localState.importPath = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('dispatches requestImport and receiveImportSuccess actions on a successful request', done => {
      const importedProject = { name: 'imported/project' };
      const importRepoId = importPayload.repo.id;
      mock.onPost(`${TEST_HOST}/endpoint.json`).reply(200, importedProject);

      testAction(
        fetchImport,
        importPayload,
        localState,
        [],
        [
          { type: 'requestImport', payload: importRepoId },
          {
            type: 'receiveImportSuccess',
            payload: {
              importedProject: convertObjectPropsToCamelCase(importedProject, { deep: true }),
              repoId: importRepoId,
            },
          },
        ],
        done,
      );
    });

    it('dispatches requestImport and receiveImportSuccess actions on an unsuccessful request', done => {
      mock.onPost(`${TEST_HOST}/endpoint.json`).reply(500);

      testAction(
        fetchImport,
        importPayload,
        localState,
        [],
        [
          { type: 'requestImport', payload: importPayload.repo.id },
          { type: 'receiveImportError', payload: { repoId: importPayload.repo.id } },
        ],
        done,
      );
    });
  });

  describe('receiveJobsSuccess', () => {
    it(`commits ${RECEIVE_JOBS_SUCCESS} mutation`, done => {
      testAction(
        receiveJobsSuccess,
        repos,
        localState,
        [{ type: RECEIVE_JOBS_SUCCESS, payload: repos }],
        [],
        done,
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

    it('dispatches requestJobs and receiveJobsSuccess actions on a successful request', done => {
      mock.onGet(`${TEST_HOST}/endpoint.json`).reply(200, updatedProjects);

      testAction(
        fetchJobs,
        null,
        localState,
        [],
        [
          {
            type: 'receiveJobsSuccess',
            payload: convertObjectPropsToCamelCase(updatedProjects, { deep: true }),
          },
        ],
        done,
      );
    });

    describe('when filtered', () => {
      beforeEach(() => {
        localState.filter = 'filter';
      });

      it('fetches realtime changes with filter applied', done => {
        mock.onGet(`${TEST_HOST}/endpoint.json?filter=filter`).reply(200, updatedProjects);

        testAction(
          fetchJobs,
          null,
          localState,
          [],
          [
            {
              type: 'receiveJobsSuccess',
              payload: convertObjectPropsToCamelCase(updatedProjects, { deep: true }),
            },
          ],
          done,
        );
      });
    });
  });
});
