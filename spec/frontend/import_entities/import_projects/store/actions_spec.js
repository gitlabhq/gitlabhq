import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import { STATUSES, PROVIDERS } from '~/import_entities/constants';
import actionsFactory from '~/import_entities/import_projects/store/actions';
import { getImportTarget } from '~/import_entities/import_projects/store/getters';
import {
  REQUEST_REPOS,
  RECEIVE_REPOS_SUCCESS,
  RECEIVE_REPOS_ERROR,
  REQUEST_IMPORT,
  RECEIVE_IMPORT_SUCCESS,
  RECEIVE_IMPORT_ERROR,
  RECEIVE_JOBS_SUCCESS,
  CANCEL_IMPORT_SUCCESS,
  SET_PAGE,
  SET_FILTER,
  SET_PAGE_CURSORS,
  SET_HAS_NEXT_PAGE,
} from '~/import_entities/import_projects/store/mutation_types';
import state from '~/import_entities/import_projects/store/state';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
  HTTP_STATUS_TOO_MANY_REQUESTS,
} from '~/lib/utils/http_status';

jest.mock('~/alert');

const MOCK_ENDPOINT = `${TEST_HOST}/endpoint.json`;
const endpoints = {
  reposPath: MOCK_ENDPOINT,
  importPath: MOCK_ENDPOINT,
  jobsPath: MOCK_ENDPOINT,
  cancelPath: MOCK_ENDPOINT,
};

const {
  clearJobsEtagPoll,
  stopJobsPolling,
  importAll,
  fetchRepos,
  fetchImport,
  cancelImport,
  fetchJobs,
  setFilter,
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
        {
          importSource: { id: importRepoId, sanitizedName },
          importedProject: { importStatus: STATUSES.NONE },
        },
        {
          importSource: { id: otherImportRepoId, sanitizedName: 's2' },
          importedProject: { importStatus: STATUSES.NONE },
        },
        {
          importSource: { id: 3, sanitizedName: 's3', incompatible: true },
          importedProject: { importStatus: STATUSES.NONE },
        },
      ],
      provider: 'provider',
    };

    localState.getImportTarget = getImportTarget(localState);
  });

  describe('fetchRepos', () => {
    let mock;
    const payload = {
      imported_projects: [{}],
      provider_repos: [{}],
      page_info: { startCursor: 'start', endCursor: 'end', hasNextPage: true },
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    describe('with a successful request', () => {
      it('commits REQUEST_REPOS, SET_PAGE, RECEIVE_REPOS_SUCCESS mutations', () => {
        mock.onGet(MOCK_ENDPOINT).reply(HTTP_STATUS_OK, payload);

        return testAction(
          fetchRepos,
          null,
          localState,
          [
            { type: REQUEST_REPOS },
            { type: SET_PAGE, payload: 1 },
            {
              type: RECEIVE_REPOS_SUCCESS,
              payload: convertObjectPropsToCamelCase(payload, { deep: true }),
            },
          ],
          [],
        );
      });

      describe('when provider is GITHUB_PROVIDER', () => {
        beforeEach(() => {
          localState.provider = PROVIDERS.GITHUB;
        });

        it('commits SET_PAGE_CURSORS instead of SET_PAGE', () => {
          mock.onGet(MOCK_ENDPOINT).reply(HTTP_STATUS_OK, payload);

          return testAction(
            fetchRepos,
            null,
            localState,
            [
              { type: REQUEST_REPOS },
              {
                type: SET_PAGE_CURSORS,
                payload: { startCursor: 'start', endCursor: 'end', hasNextPage: true },
              },
              {
                type: RECEIVE_REPOS_SUCCESS,
                payload: convertObjectPropsToCamelCase(payload, { deep: true }),
              },
            ],
            [],
          );
        });
      });

      describe('when provider is BITBUCKET_SERVER', () => {
        beforeEach(() => {
          localState.provider = PROVIDERS.BITBUCKET_SERVER;
        });

        describe.each`
          reposLength | expectedHasNextPage
          ${0}        | ${false}
          ${12}       | ${false}
          ${20}       | ${false}
          ${25}       | ${true}
        `('when reposLength is $reposLength', ({ reposLength, expectedHasNextPage }) => {
          beforeEach(() => {
            payload.provider_repos = Array(reposLength).fill({});

            mock.onGet(MOCK_ENDPOINT).reply(HTTP_STATUS_OK, payload);
          });

          it('commits SET_HAS_NEXT_PAGE', () => {
            return testAction(
              fetchRepos,
              null,
              localState,
              [
                { type: REQUEST_REPOS },
                { type: SET_PAGE, payload: 1 },
                { type: SET_HAS_NEXT_PAGE, payload: expectedHasNextPage },
                {
                  type: RECEIVE_REPOS_SUCCESS,
                  payload: convertObjectPropsToCamelCase(payload, { deep: true }),
                },
              ],
              [],
            );
          });
        });
      });
    });

    it('commits REQUEST_REPOS, RECEIVE_REPOS_ERROR mutations on an unsuccessful request', () => {
      mock.onGet(MOCK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return testAction(
        fetchRepos,
        null,
        localState,
        [{ type: REQUEST_REPOS }, { type: RECEIVE_REPOS_ERROR }],
        [],
      );
    });

    describe('with pagination params', () => {
      it('includes page in url query params', async () => {
        let requestedUrl;
        mock.onGet().reply((config) => {
          requestedUrl = config.url;
          return [HTTP_STATUS_OK, payload];
        });

        const localStateWithPage = { ...localState, pageInfo: { page: 2 } };

        await testAction(
          fetchRepos,
          null,
          localStateWithPage,
          expect.any(Array),
          expect.any(Array),
        );

        expect(requestedUrl).toBe(`${MOCK_ENDPOINT}?page=${localStateWithPage.pageInfo.page + 1}`);
      });

      describe('when provider is "github"', () => {
        beforeEach(() => {
          localState.provider = PROVIDERS.GITHUB;
        });

        it('includes cursor in url query params', async () => {
          let requestedUrl;
          mock.onGet().reply((config) => {
            requestedUrl = config.url;
            return [HTTP_STATUS_OK, payload];
          });

          const localStateWithPage = { ...localState, pageInfo: { endCursor: 'endTest' } };

          await testAction(
            fetchRepos,
            null,
            localStateWithPage,
            expect.any(Array),
            expect.any(Array),
          );

          expect(requestedUrl).toBe(`${MOCK_ENDPOINT}?after=endTest`);
        });
      });
    });

    it('correctly keeps current page on an unsuccessful request', () => {
      mock.onGet(MOCK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      const CURRENT_PAGE = 5;

      return testAction(
        fetchRepos,
        null,
        { ...localState, pageInfo: { page: CURRENT_PAGE } },
        expect.arrayContaining([]),
        [],
      );
    });

    describe('when rate limited', () => {
      it('commits RECEIVE_REPOS_ERROR and shows rate limited error message', async () => {
        mock
          .onGet(`${TEST_HOST}/endpoint.json?filtered_field=filter`)
          .reply(HTTP_STATUS_TOO_MANY_REQUESTS);

        await testAction(
          fetchRepos,
          null,
          { ...localState, filter: { filtered_field: 'filter' } },
          [{ type: REQUEST_REPOS }, { type: RECEIVE_REPOS_ERROR }],
          [],
        );

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Provider rate limit exceeded. Try again later',
        });
      });
    });

    describe('when filtered', () => {
      it('fetches repos with filter applied', () => {
        mock.onGet(`${TEST_HOST}/endpoint.json?some_filter=filter`).reply(HTTP_STATUS_OK, payload);

        return testAction(
          fetchRepos,
          null,
          { ...localState, filter: { some_filter: 'filter' } },
          [
            { type: REQUEST_REPOS },
            { type: SET_PAGE, payload: 1 },
            {
              type: RECEIVE_REPOS_SUCCESS,
              payload: convertObjectPropsToCamelCase(payload, { deep: true }),
            },
          ],
          [],
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
      mock.onPost(MOCK_ENDPOINT).reply(HTTP_STATUS_OK, importedProject);

      return testAction(
        fetchImport,
        { repoId: importRepoId, optionalStages: {} },
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
      mock.onPost(MOCK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(
        fetchImport,
        { repoId: importRepoId, optionalStages: {} },
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

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Importing the project failed',
      });
    });

    it('commits REQUEST_IMPORT and RECEIVE_IMPORT_ERROR and shows detailed error message on an unsuccessful request with errors fields in response', async () => {
      const ERROR_MESSAGE = 'dummy';
      mock
        .onPost(MOCK_ENDPOINT)
        .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, { errors: ERROR_MESSAGE });

      await testAction(
        fetchImport,
        { repoId: importRepoId, optionalStages: {} },
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

      expect(createAlert).toHaveBeenCalledWith({
        message: `Importing the project failed: ${ERROR_MESSAGE}`,
      });
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
      mock.onGet(MOCK_ENDPOINT).reply(HTTP_STATUS_OK, updatedProjects);

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
        localState.filter = { some_filter: 'filter' };
      });

      it('fetches realtime changes with filter applied', () => {
        mock
          .onGet(`${TEST_HOST}/endpoint.json?some_filter=filter`)
          .reply(HTTP_STATUS_OK, updatedProjects);

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

  describe('importAll', () => {
    it('dispatches multiple fetchImport actions', async () => {
      const OPTIONAL_STAGES = { stage1: true, stage2: false };

      await testAction(
        importAll,
        { optionalStages: OPTIONAL_STAGES },
        localState,
        [],
        [
          {
            type: 'fetchImport',
            payload: { repoId: importRepoId, optionalStages: OPTIONAL_STAGES },
          },
          {
            type: 'fetchImport',
            payload: { repoId: otherImportRepoId, optionalStages: OPTIONAL_STAGES },
          },
        ],
      );
    });
  });

  describe('setFilter', () => {
    it('dispatches sets the filter value and dispatches fetchRepos', async () => {
      await testAction(
        setFilter,
        'filteredRepo',
        localState,
        [{ type: SET_FILTER, payload: 'filteredRepo' }],
        [{ type: 'fetchRepos' }],
      );
    });
  });

  describe('cancelImport', () => {
    let mock;
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('commits CANCEL_IMPORT_SUCCESS on success', async () => {
      mock.onPost(MOCK_ENDPOINT).reply(HTTP_STATUS_OK);

      await testAction(
        cancelImport,
        { repoId: importRepoId },
        localState,
        [
          {
            type: CANCEL_IMPORT_SUCCESS,
            payload: { repoId: 1 },
          },
        ],
        [],
      );
    });

    it('shows generic error message on an unsuccessful request', async () => {
      mock.onPost(MOCK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(cancelImport, { repoId: importRepoId }, localState, [], []);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Cancelling project import failed',
      });
    });

    it('shows detailed error message on an unsuccessful request with errors fields in response', async () => {
      const ERROR_MESSAGE = 'dummy';
      mock
        .onPost(MOCK_ENDPOINT)
        .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, { errors: ERROR_MESSAGE });

      await testAction(cancelImport, { repoId: importRepoId }, localState, [], []);

      expect(createAlert).toHaveBeenCalledWith({
        message: `Cancelling project import failed: ${ERROR_MESSAGE}`,
      });
    });
  });
});
