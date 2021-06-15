import MockAdapter from 'axios-mock-adapter';
import { range } from 'lodash';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
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

const TEST_PROJECT = 'abcproject';
const TEST_PROJECT_ID = 17;

const createMergeRequestChange = (path) => ({
  new_path: path,
  path,
});
const createMergeRequestChangesCount = (n) =>
  range(n).map((i) => createMergeRequestChange(`loremispum_${i}.md`));

const testGetUrlForPath = (path) => `${TEST_HOST}/test/${path}`;

jest.mock('~/flash');

describe('IDE store merge request actions', () => {
  let store;
  let mock;

  beforeEach(() => {
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
          mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests/).reply(200, mockData);
        });

        it('calls getProjectMergeRequests service method', (done) => {
          store
            .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'bar' })
            .then(() => {
              expect(service.getProjectMergeRequests).toHaveBeenCalledWith(TEST_PROJECT, {
                source_branch: 'bar',
                source_project_id: TEST_PROJECT_ID,
                state: 'opened',
                order_by: 'created_at',
                per_page: 1,
              });

              done();
            })
            .catch(done.fail);
        });

        it('sets the "Merge Request" Object', (done) => {
          store
            .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'bar' })
            .then(() => {
              expect(store.state.projects.abcproject.mergeRequests).toEqual({
                2: expect.objectContaining(mrData),
              });
              done();
            })
            .catch(done.fail);
        });

        it('sets "Current Merge Request" object to the most recent MR', (done) => {
          store
            .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'bar' })
            .then(() => {
              expect(store.state.currentMergeRequestId).toEqual('2');
              done();
            })
            .catch(done.fail);
        });

        it('does nothing if user cannot read MRs', (done) => {
          store.state.projects[TEST_PROJECT].userPermissions[PERMISSION_READ_MR] = false;

          store
            .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'bar' })
            .then(() => {
              expect(service.getProjectMergeRequests).not.toHaveBeenCalled();
              expect(store.state.currentMergeRequestId).toBe('');
            })
            .then(done)
            .catch(done.fail);
        });
      });

      describe('no merge requests for branch available case', () => {
        beforeEach(() => {
          jest.spyOn(service, 'getProjectMergeRequests');
          mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests/).reply(200, []);
        });

        it('does not fail if there are no merge requests for current branch', (done) => {
          store
            .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'foo' })
            .then(() => {
              expect(store.state.projects[TEST_PROJECT].mergeRequests).toEqual({});
              expect(store.state.currentMergeRequestId).toEqual('');
              done();
            })
            .catch(done.fail);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests/).networkError();
      });

      it('flashes message, if error', (done) => {
        store
          .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'bar' })
          .catch(() => {
            expect(createFlash).toHaveBeenCalled();
            expect(createFlash.mock.calls[0][0].message).toBe(
              'Error fetching merge requests for bar',
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('getMergeRequestData', () => {
    describe('success', () => {
      beforeEach(() => {
        jest.spyOn(service, 'getProjectMergeRequestData');

        mock
          .onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1/)
          .reply(200, { title: 'mergerequest' });
      });

      it('calls getProjectMergeRequestData service method', (done) => {
        store
          .dispatch('getMergeRequestData', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(service.getProjectMergeRequestData).toHaveBeenCalledWith(TEST_PROJECT, 1);

            done();
          })
          .catch(done.fail);
      });

      it('sets the Merge Request Object', (done) => {
        store
          .dispatch('getMergeRequestData', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(store.state.currentMergeRequestId).toBe(1);
            expect(store.state.projects[TEST_PROJECT].mergeRequests['1'].title).toBe(
              'mergerequest',
            );

            done();
          })
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1/).networkError();
      });

      it('dispatches error action', (done) => {
        const dispatch = jest.fn();

        getMergeRequestData(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          { projectId: TEST_PROJECT, mergeRequestId: 1 },
        )
          .then(done.fail)
          .catch(() => {
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

            done();
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
          .reply(200, { title: 'mergerequest' });
      });

      it('calls getProjectMergeRequestChanges service method', (done) => {
        store
          .dispatch('getMergeRequestChanges', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(service.getProjectMergeRequestChanges).toHaveBeenCalledWith(TEST_PROJECT, 1);

            done();
          })
          .catch(done.fail);
      });

      it('sets the Merge Request Changes Object', (done) => {
        store
          .dispatch('getMergeRequestChanges', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(store.state.projects[TEST_PROJECT].mergeRequests['1'].changes.title).toBe(
              'mergerequest',
            );
            done();
          })
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/changes/).networkError();
      });

      it('dispatches error action', (done) => {
        const dispatch = jest.fn();

        getMergeRequestChanges(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          { projectId: TEST_PROJECT, mergeRequestId: 1 },
        )
          .then(done.fail)
          .catch(() => {
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

            done();
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
          .reply(200, [{ id: 789 }]);
        jest.spyOn(service, 'getProjectMergeRequestVersions');
      });

      it('calls getProjectMergeRequestVersions service method', (done) => {
        store
          .dispatch('getMergeRequestVersions', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(service.getProjectMergeRequestVersions).toHaveBeenCalledWith(TEST_PROJECT, 1);

            done();
          })
          .catch(done.fail);
      });

      it('sets the Merge Request Versions Object', (done) => {
        store
          .dispatch('getMergeRequestVersions', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(store.state.projects[TEST_PROJECT].mergeRequests['1'].versions.length).toBe(1);
            done();
          })
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/versions/).networkError();
      });

      it('dispatches error action', (done) => {
        const dispatch = jest.fn();

        getMergeRequestVersions(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          { projectId: TEST_PROJECT, mergeRequestId: 1 },
        )
          .then(done.fail)
          .catch(() => {
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

            done();
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

    it('dispatches actions for merge request data', (done) => {
      openMergeRequest({ state: store.state, dispatch: store.dispatch, getters: mockGetters }, mr)
        .then(() => {
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
        })
        .then(done)
        .catch(done.fail);
    });

    it('updates activity bar view and gets file data, if changes are found', (done) => {
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

      openMergeRequest({ state: store.state, dispatch: store.dispatch, getters: mockGetters }, mr)
        .then(() => {
          expect(store.dispatch).toHaveBeenCalledWith(
            'openMergeRequestChanges',
            testMergeRequestChanges.changes,
          );
        })
        .then(done)
        .catch(done.fail);
    });

    it('flashes message, if error', (done) => {
      store.dispatch.mockRejectedValue();

      openMergeRequest(store, mr)
        .catch(() => {
          expect(createFlash).toHaveBeenCalledWith({
            message: expect.any(String),
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
