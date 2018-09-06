import { uniqueId } from 'underscore';
import { TEST_HOST } from 'helpers/constants';
import axiosMock from 'helpers/axios_mock';
import createMockWebworker from 'helpers/mock_webworker';
import { createVuexContext } from 'helpers/vuex';
import createState from '~/ide/stores/state';
import {
  CREATE_TREE,
  SET_TREE_OPEN,
  TOGGLE_TREE_OPEN,
  SET_ENTRIES,
  SET_DIRECTORY_DATA,
  TOGGLE_LOADING,
} from '~/ide/stores/mutation_types';
import { getFiles, showTreeEntry, toggleTreeOpen } from '~/ide/stores/actions/tree';
import { createEntriesFromPaths, file } from '../../helpers';

const mockFilesDecoratorWorker = createMockWebworker();
jest.mock('~/ide/stores/workers/files_decorator_worker', () =>
  jest.fn(() => mockFilesDecoratorWorker),
);

describe('Multi-file store tree actions', () => {
  let commit;
  let dispatch;
  let state;

  beforeEach(() => {
    ({ commit, dispatch, state } = createVuexContext(createState));
    mockFilesDecoratorWorker.mockClear();
  });

  describe('getFiles', () => {
    const tree = 'selected tree';

    let branchId;
    let projectId;
    let treePath;
    let dummyProject;

    beforeEach(() => {
      branchId = uniqueId('branch-');
      projectId = uniqueId('project-');
      treePath = `${projectId}/${branchId}`;
      dummyProject = {
        web_url: `${TEST_HOST}/project/url`,
      };

      state.projects[projectId] = dummyProject;
    });

    describe('for successful response', () => {
      const responseData = 'dummy response';
      const workerData = { entries: 'dummy entries', treeList: 'dummy tree list' };

      beforeEach(() => {
        axiosMock.onGet(`${dummyProject.web_url}/files/${branchId}`).replyOnce(200, responseData);

        mockFilesDecoratorWorker.addEventListener.mockImplementationOnce((eventName, listener) => {
          expect(eventName).toBe('message');
          expect(listener).toBeInstanceOf(Function);

          expect(commit).toHaveBeenCalledWith(CREATE_TREE, { treePath });
          state.trees[treePath] = tree;
          commit.mockClear();

          listener({ data: workerData });

          expect(mockFilesDecoratorWorker.terminate).toHaveBeenCalled();
        });
      });

      it('triggers FilesDecoratorWorker', done => {
        mockFilesDecoratorWorker.addEventListener.mockReset();
        mockFilesDecoratorWorker.postMessage.mockImplementationOnce(message => {
          expect(message.data).toBe(responseData);
          expect(message.projectId).toBe(projectId);
          expect(message.branchId).toBe(branchId);

          expect(commit).toHaveBeenCalledTimes(1);
          expect(commit).toHaveBeenCalledWith(CREATE_TREE, { treePath });
          expect(dispatch).not.toHaveBeenCalled();

          done();
        });

        getFiles({ commit, dispatch, state }, { projectId, branchId });
      });

      it('stores result from FilesDecoratorWorker', () =>
        getFiles({ commit, dispatch, state }, { projectId, branchId }).then(() => {
          expect(mockFilesDecoratorWorker.addEventListener).toHaveBeenCalled();

          expect(commit).toHaveBeenCalledTimes(3);
          expect(commit).toHaveBeenCalledWith(SET_ENTRIES, workerData.entries);
          expect(commit).toHaveBeenCalledWith(SET_DIRECTORY_DATA, {
            data: workerData.treeList,
            treePath,
          });
          expect(commit).toHaveBeenCalledWith(TOGGLE_LOADING, {
            entry: tree,
            forceValue: false,
          });
          expect(dispatch).not.toHaveBeenCalled();
        }));
    });

    describe('for error response', () => {
      beforeEach(() => {
        axiosMock.onGet(`${dummyProject.web_url}/files/${branchId}`).replyOnce(500, null);
      });

      it('displays an error message', () => {
        expect.assertions(11);

        return getFiles({ commit, dispatch, state }, { projectId, branchId }).catch(() => {
          expect(commit).toHaveBeenCalledTimes(1);
          expect(commit).toHaveBeenCalledWith(CREATE_TREE, { treePath });
          expect(dispatch).toHaveBeenCalledTimes(1);
          expect(dispatch).toHaveBeenCalledWith('setErrorMessage', expect.any(Object));

          const errorMessage = dispatch.mock.calls[0][1];
          expect(errorMessage.action).toBeInstanceOf(Function);
          expect(errorMessage.actionPayload).toEqual({ branchId, projectId });
          expect(errorMessage.actionText).toBe('Please try again');
          expect(errorMessage.text).toBeString();

          dispatch.mockClear();
          return errorMessage.action(errorMessage.actionPayload).then(() => {
            expect(dispatch).toHaveBeenCalledTimes(2);
            expect(dispatch).toHaveBeenCalledWith('getFiles', errorMessage.actionPayload);
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', null);
          });
        });
      });
    });
  });

  describe('showTreeEntry', () => {
    it('opens the parents', () => {
      const paths = [
        'grandparent',
        'ancestor',
        'grandparent/parent',
        'grandparent/aunt',
        'grandparent/parent/child.txt',
        'grandparent/aunt/cousing.txt',
      ];
      state.entries = createEntriesFromPaths(paths);

      showTreeEntry({ commit, dispatch, state }, 'grandparent/parent/child.txt');

      expect(commit).toHaveBeenCalledTimes(1);
      expect(commit).toHaveBeenCalledWith(SET_TREE_OPEN, 'grandparent/parent');
      expect(dispatch).toHaveBeenCalledTimes(1);
      expect(dispatch).toHaveBeenCalledWith('showTreeEntry', 'grandparent/parent');
    });
  });

  describe('toggleTreeOpen', () => {
    let tree;

    beforeEach(() => {
      tree = file('testing', '1', 'tree');
      state.entries[tree.path] = tree;
    });

    it('toggles the tree open', () => {
      toggleTreeOpen({ commit }, tree.path);

      expect(commit).toHaveBeenCalledTimes(1);
      expect(commit).toHaveBeenCalledWith(TOGGLE_TREE_OPEN, tree.path);
    });
  });
});
