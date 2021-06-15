import MockAdapter from 'axios-mock-adapter';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import testAction from 'helpers/vuex_action_helper';
import api from '~/api';
import service from '~/ide/services';
import { createStore } from '~/ide/stores';
import {
  refreshLastCommitData,
  showBranchNotFoundError,
  createNewBranchFromDefault,
  loadEmptyBranch,
  openBranch,
  loadFile,
  loadBranch,
} from '~/ide/stores/actions';
import axios from '~/lib/utils/axios_utils';

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

    it('calls the service', (done) => {
      store
        .dispatch('refreshLastCommitData', {
          projectId: store.state.currentProjectId,
          branchId: store.state.currentBranchId,
        })
        .then(() => {
          expect(service.getBranchData).toHaveBeenCalledWith('abc/def', 'main');

          done();
        })
        .catch(done.fail);
    });

    it('commits getBranchData', (done) => {
      testAction(
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
        done,
      );
    });
  });

  describe('showBranchNotFoundError', () => {
    it('dispatches setErrorMessage', (done) => {
      testAction(
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
        done,
      );
    });
  });

  describe('createNewBranchFromDefault', () => {
    useMockLocationHelper();

    beforeEach(() => {
      jest.spyOn(api, 'createBranch').mockResolvedValue();
    });

    it('calls API', (done) => {
      createNewBranchFromDefault(
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
      )
        .then(() => {
          expect(api.createBranch).toHaveBeenCalledWith('project-path', {
            ref: 'main',
            branch: 'new-branch-name',
          });
        })
        .then(done)
        .catch(done.fail);
    });

    it('clears error message', (done) => {
      const dispatchSpy = jest.fn().mockName('dispatch');

      createNewBranchFromDefault(
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
      )
        .then(() => {
          expect(dispatchSpy).toHaveBeenCalledWith('setErrorMessage', null);
        })
        .then(done)
        .catch(done.fail);
    });

    it('reloads window', (done) => {
      createNewBranchFromDefault(
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
      )
        .then(() => {
          expect(window.location.reload).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('loadEmptyBranch', () => {
    it('creates a blank tree and sets loading state to false', (done) => {
      testAction(
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
        done,
      );
    });

    it('does nothing, if tree already exists', (done) => {
      const trees = { [`${TEST_PROJECT_ID}/main`]: [] };

      testAction(
        loadEmptyBranch,
        { projectId: TEST_PROJECT_ID, branchId: 'main' },
        { trees },
        [],
        [],
        done,
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

    it('when empty repo, loads empty branch', (done) => {
      const mockGetters = { emptyRepo: true };

      testAction(
        loadBranch,
        { projectId, branchId },
        { ...store.state, ...mockGetters },
        [],
        [{ type: 'loadEmptyBranch', payload: { projectId, branchId } }],
        done,
      );
    });

    it('when branch already exists, does nothing', (done) => {
      store.state.projects[projectId].branches[branchId] = {};

      testAction(loadBranch, { projectId, branchId }, store.state, [], [], done);
    });

    it('fetches branch data', (done) => {
      const mockGetters = { findBranch: () => ({ commit: { id: ref } }) };
      jest.spyOn(store, 'dispatch').mockResolvedValue();

      loadBranch(
        { getters: mockGetters, state: store.state, dispatch: store.dispatch },
        { projectId, branchId },
      )
        .then(() => {
          expect(store.dispatch.mock.calls).toEqual([
            ['getBranchData', { projectId, branchId }],
            ['getMergeRequestsForBranch', { projectId, branchId }],
            ['getFiles', { projectId, branchId, ref }],
          ]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows an error if branch can not be fetched', (done) => {
      jest.spyOn(store, 'dispatch').mockReturnValue(Promise.reject());

      loadBranch(store, { projectId, branchId })
        .then(done.fail)
        .catch(() => {
          expect(store.dispatch.mock.calls).toEqual([
            ['getBranchData', { projectId, branchId }],
            ['showBranchNotFoundError', branchId],
          ]);
          done();
        });
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

      it('dispatches branch actions', (done) => {
        openBranch(store, branch)
          .then(() => {
            expect(store.dispatch.mock.calls).toEqual([
              ['setCurrentBranchId', branchId],
              ['loadBranch', { projectId, branchId }],
              ['loadFile', { basePath: undefined }],
            ]);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('non-existent branch', () => {
      beforeEach(() => {
        jest.spyOn(store, 'dispatch').mockReturnValue(Promise.reject());
      });

      it('dispatches correct branch actions', (done) => {
        openBranch(store, branch)
          .then((val) => {
            expect(store.dispatch.mock.calls).toEqual([
              ['setCurrentBranchId', branchId],
              ['loadBranch', { projectId, branchId }],
            ]);

            expect(val).toEqual(
              new Error(
                `An error occurred while getting files for - <strong>${projectId}/${branchId}</strong>`,
              ),
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
