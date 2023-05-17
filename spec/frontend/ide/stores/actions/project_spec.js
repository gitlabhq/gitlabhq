import MockAdapter from 'axios-mock-adapter';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import testAction from 'helpers/vuex_action_helper';
import api from '~/api';
import { createAlert } from '~/alert';
import service from '~/ide/services';
import { createStore } from '~/ide/stores';
import {
  setProject,
  fetchProjectPermissions,
  refreshLastCommitData,
  showBranchNotFoundError,
  createNewBranchFromDefault,
  loadEmptyBranch,
  openBranch,
  loadFile,
  loadBranch,
} from '~/ide/stores/actions';
import { logError } from '~/lib/logger';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/alert');
jest.mock('~/lib/logger');

const TEST_PROJECT_ID = 'abc/def';

describe('IDE store project actions', () => {
  let mock;
  let store;

  beforeEach(() => {
    store = createStore();
    mock = new MockAdapter(axios);

    store.state.projects[TEST_PROJECT_ID] = {
      branches: {},
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setProject', () => {
    const project = { id: 'foo', path_with_namespace: TEST_PROJECT_ID };
    const baseMutations = [
      {
        type: 'SET_PROJECT',
        payload: {
          projectPath: TEST_PROJECT_ID,
          project,
        },
      },
      {
        type: 'SET_CURRENT_PROJECT',
        payload: TEST_PROJECT_ID,
      },
    ];

    it.each`
      desc                                                         | payload        | expectedMutations
      ${'does not commit any action if project is not passed'}     | ${undefined}   | ${[]}
      ${'commits correct actions in the correct order by default'} | ${{ project }} | ${[...baseMutations]}
    `('$desc', async ({ payload, expectedMutations } = {}) => {
      await testAction({
        action: setProject,
        payload,
        state: store.state,
        expectedMutations,
        expectedActions: [],
      });
    });
  });

  describe('fetchProjectPermissions', () => {
    const permissionsData = {
      userPermissions: {
        bogus: true,
      },
    };
    const permissionsMutations = [
      {
        type: 'UPDATE_PROJECT',
        payload: {
          projectPath: TEST_PROJECT_ID,
          props: {
            ...permissionsData,
          },
        },
      },
    ];

    let spy;

    beforeEach(() => {
      spy = jest.spyOn(service, 'getProjectPermissionsData');
    });

    afterEach(() => {
      createAlert.mockRestore();
    });

    it.each`
      desc                                                      | projectPath        | responseSuccess | expectedMutations
      ${'does not fetch permissions if project does not exist'} | ${undefined}       | ${true}         | ${[]}
      ${'fetches permission when project is specified'}         | ${TEST_PROJECT_ID} | ${true}         | ${[...permissionsMutations]}
      ${'alerts an error if the request fails'}                 | ${TEST_PROJECT_ID} | ${false}        | ${[]}
    `('$desc', async ({ projectPath, expectedMutations, responseSuccess } = {}) => {
      store.state.currentProjectId = projectPath;
      if (responseSuccess) {
        spy.mockResolvedValue(permissionsData);
      } else {
        spy.mockRejectedValue();
      }

      await testAction({
        action: fetchProjectPermissions,
        state: store.state,
        expectedMutations,
        expectedActions: [],
      });

      if (!responseSuccess) {
        expect(logError).toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalled();
      }
    });
  });

  describe('refreshLastCommitData', () => {
    beforeEach(() => {
      store.state.currentProjectId = 'abc/def';
      store.state.currentBranchId = 'main';
      store.state.projects['abc/def'] = {
        id: 4,
        branches: {
          main: {
            commit: null,
          },
        },
      };
      jest.spyOn(service, 'getBranchData').mockResolvedValue({
        data: {
          commit: { id: '123' },
        },
      });
    });

    it('calls the service', async () => {
      await store.dispatch('refreshLastCommitData', {
        projectId: store.state.currentProjectId,
        branchId: store.state.currentBranchId,
      });
      expect(service.getBranchData).toHaveBeenCalledWith('abc/def', 'main');
    });

    it('commits getBranchData', () => {
      return testAction(
        refreshLastCommitData,
        {
          projectId: store.state.currentProjectId,
          branchId: store.state.currentBranchId,
        },
        store.state,
        // mutations
        [
          {
            type: 'SET_BRANCH_COMMIT',
            payload: {
              projectId: TEST_PROJECT_ID,
              branchId: 'main',
              commit: { id: '123' },
            },
          },
        ],
        // action
        [],
      );
    });
  });

  describe('showBranchNotFoundError', () => {
    it('dispatches setErrorMessage', () => {
      return testAction(
        showBranchNotFoundError,
        'main',
        null,
        [],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: "Branch <strong>main</strong> was not found in this project's repository.",
              action: expect.any(Function),
              actionText: 'Create branch',
              actionPayload: 'main',
            },
          },
        ],
      );
    });
  });

  describe('createNewBranchFromDefault', () => {
    useMockLocationHelper();

    beforeEach(() => {
      jest.spyOn(api, 'createBranch').mockResolvedValue();
    });

    it('calls API', async () => {
      await createNewBranchFromDefault(
        {
          state: {
            currentProjectId: 'project-path',
          },
          getters: {
            currentProject: {
              default_branch: 'main',
            },
          },
          dispatch() {},
        },
        'new-branch-name',
      );
      expect(api.createBranch).toHaveBeenCalledWith('project-path', {
        ref: 'main',
        branch: 'new-branch-name',
      });
    });

    it('clears error message', async () => {
      const dispatchSpy = jest.fn().mockName('dispatch');

      await createNewBranchFromDefault(
        {
          state: {
            currentProjectId: 'project-path',
          },
          getters: {
            currentProject: {
              default_branch: 'main',
            },
          },
          dispatch: dispatchSpy,
        },
        'new-branch-name',
      );
      expect(dispatchSpy).toHaveBeenCalledWith('setErrorMessage', null);
    });

    it('reloads window', async () => {
      await createNewBranchFromDefault(
        {
          state: {
            currentProjectId: 'project-path',
          },
          getters: {
            currentProject: {
              default_branch: 'main',
            },
          },
          dispatch() {},
        },
        'new-branch-name',
      );
      expect(window.location.reload).toHaveBeenCalled();
    });
  });

  describe('loadEmptyBranch', () => {
    it('creates a blank tree and sets loading state to false', () => {
      return testAction(
        loadEmptyBranch,
        { projectId: TEST_PROJECT_ID, branchId: 'main' },
        store.state,
        [
          { type: 'CREATE_TREE', payload: { treePath: `${TEST_PROJECT_ID}/main` } },
          {
            type: 'TOGGLE_LOADING',
            payload: { entry: store.state.trees[`${TEST_PROJECT_ID}/main`], forceValue: false },
          },
        ],
        expect.any(Object),
      );
    });

    it('does nothing, if tree already exists', () => {
      const trees = { [`${TEST_PROJECT_ID}/main`]: [] };

      return testAction(
        loadEmptyBranch,
        { projectId: TEST_PROJECT_ID, branchId: 'main' },
        { trees },
        [],
        [],
      );
    });
  });

  describe('loadFile', () => {
    beforeEach(() => {
      Object.assign(store.state, {
        entries: {
          foo: { pending: false },
          'foo/bar-pending': { pending: true },
          'foo/bar': { pending: false },
        },
      });
      jest.spyOn(store, 'dispatch').mockImplementation();
    });

    it('does nothing, if basePath is not given', () => {
      loadFile(store, { basePath: undefined });

      expect(store.dispatch).not.toHaveBeenCalled();
    });

    it('handles tree entry action, if basePath is given and the entry is not pending', () => {
      loadFile(store, { basePath: 'foo/bar/' });

      expect(store.dispatch).toHaveBeenCalledWith(
        'handleTreeEntryAction',
        store.state.entries['foo/bar'],
      );
    });

    it('does not handle tree entry action, if entry is pending', () => {
      loadFile(store, { basePath: 'foo/bar-pending/' });

      expect(store.dispatch).not.toHaveBeenCalledWith('handleTreeEntryAction', expect.anything());
    });

    it('creates a new temp file supplied via URL if the file does not exist yet', () => {
      loadFile(store, { basePath: 'not-existent.md' });

      expect(store.dispatch.mock.calls).toHaveLength(1);

      expect(store.dispatch).not.toHaveBeenCalledWith('handleTreeEntryAction', expect.anything());

      expect(store.dispatch).toHaveBeenCalledWith('createTempEntry', {
        name: 'not-existent.md',
        type: 'blob',
      });
    });
  });

  describe('loadBranch', () => {
    const projectId = TEST_PROJECT_ID;
    const branchId = '123-lorem';
    const ref = 'abcd2322';

    it('when empty repo, loads empty branch', () => {
      const mockGetters = { emptyRepo: true };

      return testAction(
        loadBranch,
        { projectId, branchId },
        { ...store.state, ...mockGetters },
        [],
        [{ type: 'loadEmptyBranch', payload: { projectId, branchId } }],
      );
    });

    it('when branch already exists, does nothing', () => {
      store.state.projects[projectId].branches[branchId] = {};

      return testAction(loadBranch, { projectId, branchId }, store.state, [], []);
    });

    it('fetches branch data', async () => {
      const mockGetters = { findBranch: () => ({ commit: { id: ref } }) };
      jest.spyOn(store, 'dispatch').mockResolvedValue();

      await loadBranch(
        { getters: mockGetters, state: store.state, dispatch: store.dispatch },
        { projectId, branchId },
      );
      expect(store.dispatch.mock.calls).toEqual([
        ['getBranchData', { projectId, branchId }],
        ['getMergeRequestsForBranch', { projectId, branchId }],
        ['getFiles', { projectId, branchId, ref }],
      ]);
    });

    it('shows an error if branch can not be fetched', async () => {
      jest.spyOn(store, 'dispatch').mockReturnValue(Promise.reject());

      await expect(loadBranch(store, { projectId, branchId })).rejects.toBeUndefined();

      expect(store.dispatch.mock.calls).toEqual([
        ['getBranchData', { projectId, branchId }],
        ['showBranchNotFoundError', branchId],
      ]);
    });
  });

  describe('openBranch', () => {
    const projectId = TEST_PROJECT_ID;
    const branchId = '123-lorem';

    const branch = {
      projectId,
      branchId,
    };

    beforeEach(() => {
      Object.assign(store.state, {
        entries: {
          foo: { pending: false },
          'foo/bar-pending': { pending: true },
          'foo/bar': { pending: false },
        },
      });
    });

    describe('existing branch', () => {
      beforeEach(() => {
        jest.spyOn(store, 'dispatch').mockResolvedValue();
      });

      it('dispatches branch actions', async () => {
        await openBranch(store, branch);
        expect(store.dispatch.mock.calls).toEqual([
          ['setCurrentBranchId', branchId],
          ['loadBranch', { projectId, branchId }],
          ['loadFile', { basePath: undefined }],
        ]);
      });
    });

    describe('non-existent branch', () => {
      beforeEach(() => {
        jest.spyOn(store, 'dispatch').mockReturnValue(Promise.reject());
      });

      it('dispatches correct branch actions', async () => {
        const val = await openBranch(store, branch);
        expect(store.dispatch.mock.calls).toEqual([
          ['setCurrentBranchId', branchId],
          ['loadBranch', { projectId, branchId }],
        ]);

        expect(val).toEqual(
          new Error(
            `An error occurred while getting files for - <strong>${projectId}/${branchId}</strong>`,
          ),
        );
      });
    });
  });
});
