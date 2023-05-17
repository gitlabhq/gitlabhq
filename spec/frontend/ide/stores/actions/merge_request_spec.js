import MockAdapter from 'axios-mock-adapter';
import { range } from 'lodash';
import { stubPerformanceWebAPI } from 'helpers/performance';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import { leftSidebarViews, PERMISSION_READ_MR, MAX_MR_FILES_AUTO_OPEN } from '~/ide/constants';
import service from '~/ide/services';
import { createStore } from '~/ide/stores';
import {
  getMergeRequestData,
  getMergeRequestChanges,
  getMergeRequestVersions,
  openMergeRequestChanges,
  openMergeRequest,
} from '~/ide/stores/actions/merge_request';
import * as types from '~/ide/stores/mutation_types';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const TEST_PROJECT = 'abcproject';
const TEST_PROJECT_ID = 17;

const createMergeRequestChange = (path) => ({
  new_path: path,
  path,
});
const createMergeRequestChangesCount = (n) =>
  range(n).map((i) => createMergeRequestChange(`loremispum_${i}.md`));

const testGetUrlForPath = (path) => `${TEST_HOST}/test/${path}`;

jest.mock('~/alert');

describe('IDE store merge request actions', () => {
  let store;
  let mock;

  beforeEach(() => {
    stubPerformanceWebAPI();

    store = createStore();

    mock = new MockAdapter(axios);

    store.state.projects[TEST_PROJECT] = {
      id: TEST_PROJECT_ID,
      mergeRequests: {},
      userPermissions: {
        [PERMISSION_READ_MR]: true,
      },
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('getMergeRequestsForBranch', () => {
    describe('success', () => {
      const mrData = { iid: 2, source_branch: 'bar' };
      const mockData = [mrData];

      describe('base case', () => {
        beforeEach(() => {
          jest.spyOn(service, 'getProjectMergeRequests');
          mock
            .onGet(/api\/(.*)\/projects\/abcproject\/merge_requests/)
            .reply(HTTP_STATUS_OK, mockData);
        });

        it('calls getProjectMergeRequests service method', async () => {
          await store.dispatch('getMergeRequestsForBranch', {
            projectId: TEST_PROJECT,
            branchId: 'bar',
          });
          expect(service.getProjectMergeRequests).toHaveBeenCalledWith(TEST_PROJECT, {
            source_branch: 'bar',
            source_project_id: TEST_PROJECT_ID,
            state: 'opened',
            order_by: 'created_at',
            per_page: 1,
          });
        });

        it('sets the "Merge Request" Object', async () => {
          await store.dispatch('getMergeRequestsForBranch', {
            projectId: TEST_PROJECT,
            branchId: 'bar',
          });
          expect(store.state.projects.abcproject.mergeRequests).toEqual({
            2: expect.objectContaining(mrData),
          });
        });

        it('sets "Current Merge Request" object to the most recent MR', async () => {
          await store.dispatch('getMergeRequestsForBranch', {
            projectId: TEST_PROJECT,
            branchId: 'bar',
          });
          expect(store.state.currentMergeRequestId).toEqual('2');
        });

        it('does nothing if user cannot read MRs', async () => {
          store.state.projects[TEST_PROJECT].userPermissions[PERMISSION_READ_MR] = false;

          await store.dispatch('getMergeRequestsForBranch', {
            projectId: TEST_PROJECT,
            branchId: 'bar',
          });
          expect(service.getProjectMergeRequests).not.toHaveBeenCalled();
          expect(store.state.currentMergeRequestId).toBe('');
        });
      });

      describe('no merge requests for branch available case', () => {
        beforeEach(() => {
          jest.spyOn(service, 'getProjectMergeRequests');
          mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests/).reply(HTTP_STATUS_OK, []);
        });

        it('does not fail if there are no merge requests for current branch', async () => {
          await store.dispatch('getMergeRequestsForBranch', {
            projectId: TEST_PROJECT,
            branchId: 'foo',
          });
          expect(store.state.projects[TEST_PROJECT].mergeRequests).toEqual({});
          expect(store.state.currentMergeRequestId).toEqual('');
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests/).networkError();
      });

      it('shows an alert, if error', () => {
        return store
          .dispatch('getMergeRequestsForBranch', {
            projectId: TEST_PROJECT,
            branchId: 'bar',
          })
          .catch(() => {
            expect(createAlert).toHaveBeenCalled();
            expect(createAlert.mock.calls[0][0].message).toBe(
              'Error fetching merge requests for bar',
            );
          });
      });
    });
  });

  describe('getMergeRequestData', () => {
    describe('success', () => {
      beforeEach(() => {
        jest.spyOn(service, 'getProjectMergeRequestData');

        mock
          .onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1/)
          .reply(HTTP_STATUS_OK, { title: 'mergerequest' });
      });

      it('calls getProjectMergeRequestData service method', async () => {
        await store.dispatch('getMergeRequestData', { projectId: TEST_PROJECT, mergeRequestId: 1 });
        expect(service.getProjectMergeRequestData).toHaveBeenCalledWith(TEST_PROJECT, 1);
      });

      it('sets the Merge Request Object', async () => {
        await store.dispatch('getMergeRequestData', { projectId: TEST_PROJECT, mergeRequestId: 1 });
        expect(store.state.currentMergeRequestId).toBe(1);
        expect(store.state.projects[TEST_PROJECT].mergeRequests['1'].title).toBe('mergerequest');
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1/).networkError();
      });

      it('dispatches error action', () => {
        const dispatch = jest.fn();

        return getMergeRequestData(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          { projectId: TEST_PROJECT, mergeRequestId: 1 },
        ).catch(() => {
          expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
            text: 'An error occurred while loading the merge request.',
            action: expect.any(Function),
            actionText: 'Please try again',
            actionPayload: {
              projectId: TEST_PROJECT,
              mergeRequestId: 1,
              force: false,
            },
          });
        });
      });
    });
  });

  describe('getMergeRequestChanges', () => {
    beforeEach(() => {
      store.state.projects[TEST_PROJECT].mergeRequests['1'] = { changes: [] };
    });

    describe('success', () => {
      beforeEach(() => {
        jest.spyOn(service, 'getProjectMergeRequestChanges');

        mock
          .onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/changes/)
          .reply(HTTP_STATUS_OK, { title: 'mergerequest' });
      });

      it('calls getProjectMergeRequestChanges service method', async () => {
        await store.dispatch('getMergeRequestChanges', {
          projectId: TEST_PROJECT,
          mergeRequestId: 1,
        });
        expect(service.getProjectMergeRequestChanges).toHaveBeenCalledWith(TEST_PROJECT, 1);
      });

      it('sets the Merge Request Changes Object', async () => {
        await store.dispatch('getMergeRequestChanges', {
          projectId: TEST_PROJECT,
          mergeRequestId: 1,
        });
        expect(store.state.projects[TEST_PROJECT].mergeRequests['1'].changes.title).toBe(
          'mergerequest',
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/changes/).networkError();
      });

      it('dispatches error action', async () => {
        const dispatch = jest.fn();

        await expect(
          getMergeRequestChanges(
            {
              commit() {},
              dispatch,
              state: store.state,
            },
            { projectId: TEST_PROJECT, mergeRequestId: 1 },
          ),
        ).rejects.toEqual(new Error('Merge request changes not loaded abcproject'));

        expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
          text: 'An error occurred while loading the merge request changes.',
          action: expect.any(Function),
          actionText: 'Please try again',
          actionPayload: {
            projectId: TEST_PROJECT,
            mergeRequestId: 1,
            force: false,
          },
        });
      });
    });
  });

  describe('getMergeRequestVersions', () => {
    beforeEach(() => {
      store.state.projects[TEST_PROJECT].mergeRequests['1'] = { versions: [] };
    });

    describe('success', () => {
      beforeEach(() => {
        mock
          .onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/versions/)
          .reply(HTTP_STATUS_OK, [{ id: 789 }]);
        jest.spyOn(service, 'getProjectMergeRequestVersions');
      });

      it('calls getProjectMergeRequestVersions service method', async () => {
        await store.dispatch('getMergeRequestVersions', {
          projectId: TEST_PROJECT,
          mergeRequestId: 1,
        });
        expect(service.getProjectMergeRequestVersions).toHaveBeenCalledWith(TEST_PROJECT, 1);
      });

      it('sets the Merge Request Versions Object', async () => {
        await store.dispatch('getMergeRequestVersions', {
          projectId: TEST_PROJECT,
          mergeRequestId: 1,
        });
        expect(store.state.projects[TEST_PROJECT].mergeRequests['1'].versions.length).toBe(1);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/versions/).networkError();
      });

      it('dispatches error action', () => {
        const dispatch = jest.fn();

        return getMergeRequestVersions(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          { projectId: TEST_PROJECT, mergeRequestId: 1 },
        ).catch(() => {
          expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
            text: 'An error occurred while loading the merge request version data.',
            action: expect.any(Function),
            actionText: 'Please try again',
            actionPayload: {
              projectId: TEST_PROJECT,
              mergeRequestId: 1,
              force: false,
            },
          });
        });
      });
    });
  });

  describe('openMergeRequestChanges', () => {
    it.each`
      desc                                   | changes                     | entries
      ${'with empty changes'}                | ${[]}                       | ${{}}
      ${'with changes not matching entries'} | ${[{ new_path: '123.md' }]} | ${{ '456.md': {} }}
    `('$desc, does nothing', ({ changes, entries }) => {
      const state = { entries };

      return testAction({
        action: openMergeRequestChanges,
        state,
        payload: changes,
        expectedActions: [],
        expectedMutations: [],
      });
    });

    it('updates views and opens mr changes', () => {
      // This is the payload sent to the action
      const changesPayload = createMergeRequestChangesCount(15);

      // Remove some items from the payload to use for entries
      const changes = changesPayload.slice(1, 14);

      const entries = changes.reduce(
        (acc, { path }) => Object.assign(acc, { [path]: path, type: 'blob' }),
        {},
      );
      const pathsToOpen = changes.slice(0, MAX_MR_FILES_AUTO_OPEN).map((x) => x.new_path);

      return testAction({
        action: openMergeRequestChanges,
        state: { entries, getUrlForPath: testGetUrlForPath },
        payload: changesPayload,
        expectedActions: [
          { type: 'updateActivityBarView', payload: leftSidebarViews.review.name },
          // Only activates first file
          { type: 'router/push', payload: testGetUrlForPath(pathsToOpen[0]) },
          { type: 'setFileActive', payload: pathsToOpen[0] },
          // Fetches data for other files
          ...pathsToOpen.slice(1).map((path) => ({
            type: 'getFileData',
            payload: { path, makeFileActive: false },
          })),
          ...pathsToOpen.slice(1).map((path) => ({
            type: 'getRawFileData',
            payload: { path },
          })),
        ],
        expectedMutations: [
          ...changes.map((change) => ({
            type: types.SET_FILE_MERGE_REQUEST_CHANGE,
            payload: {
              file: entries[change.new_path],
              mrChange: change,
            },
          })),
          ...pathsToOpen.map((path) => ({
            type: types.TOGGLE_FILE_OPEN,
            payload: path,
          })),
        ],
      });
    });
  });

  describe('openMergeRequest', () => {
    const mr = {
      projectId: TEST_PROJECT,
      targetProjectId: 'defproject',
      mergeRequestId: 2,
    };
    let testMergeRequest;
    let testMergeRequestChanges;

    const mockGetters = { findBranch: () => ({ commit: { id: 'abcd2322' } }) };

    beforeEach(() => {
      testMergeRequest = {
        source_branch: 'abcbranch',
      };
      testMergeRequestChanges = {
        changes: [],
      };
      store.state.entries = {
        foo: {
          type: 'blob',
        },
        bar: {
          type: 'blob',
        },
      };

      store.state.currentProjectId = 'test/test';
      store.state.currentBranchId = 'main';

      store.state.projects['test/test'] = {
        branches: {
          main: {
            commit: {
              id: '7297abc',
            },
          },
          abcbranch: {
            commit: {
              id: '29020fc',
            },
          },
        },
      };

      const originalDispatch = store.dispatch;

      jest.spyOn(store, 'dispatch').mockImplementation((type, payload) => {
        switch (type) {
          case 'getMergeRequestData':
            return Promise.resolve(testMergeRequest);
          case 'getMergeRequestChanges':
            return Promise.resolve(testMergeRequestChanges);
          case 'getFiles':
          case 'getMergeRequestVersions':
          case 'getBranchData':
            return Promise.resolve();
          default:
            return originalDispatch(type, payload);
        }
      });
      jest.spyOn(service, 'getFileData').mockImplementation(() =>
        Promise.resolve({
          headers: {},
        }),
      );
    });

    it('dispatches actions for merge request data', async () => {
      await openMergeRequest(
        { state: store.state, dispatch: store.dispatch, getters: mockGetters },
        mr,
      );
      expect(store.dispatch.mock.calls).toEqual([
        ['getMergeRequestData', mr],
        ['setCurrentBranchId', testMergeRequest.source_branch],
        [
          'getBranchData',
          {
            projectId: mr.projectId,
            branchId: testMergeRequest.source_branch,
          },
        ],
        [
          'getFiles',
          {
            projectId: mr.projectId,
            branchId: testMergeRequest.source_branch,
            ref: 'abcd2322',
          },
        ],
        ['getMergeRequestVersions', mr],
        ['getMergeRequestChanges', mr],
        ['openMergeRequestChanges', testMergeRequestChanges.changes],
      ]);
    });

    it('updates activity bar view and gets file data, if changes are found', async () => {
      store.state.entries.foo = {
        type: 'blob',
        path: 'foo',
      };
      store.state.entries.bar = {
        type: 'blob',
        path: 'bar',
      };

      testMergeRequestChanges.changes = [
        { new_path: 'foo', path: 'foo' },
        { new_path: 'bar', path: 'bar' },
      ];

      await openMergeRequest(
        { state: store.state, dispatch: store.dispatch, getters: mockGetters },
        mr,
      );
      expect(store.dispatch).toHaveBeenCalledWith(
        'openMergeRequestChanges',
        testMergeRequestChanges.changes,
      );
    });

    it('shows an alert, if error', () => {
      store.dispatch.mockRejectedValue();

      return openMergeRequest(store, mr).catch(() => {
        expect(createAlert).toHaveBeenCalledWith({
          message: expect.any(String),
        });
      });
    });
  });
});
