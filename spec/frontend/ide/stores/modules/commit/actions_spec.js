import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { file } from 'jest/ide/helpers';
import { commitActionTypes, PERMISSION_CREATE_MR } from '~/ide/constants';
import eventHub from '~/ide/eventhub';
import { createRouter } from '~/ide/ide_router';
import { createUnexpectedCommitError } from '~/ide/lib/errors';
import service from '~/ide/services';
import { createStore } from '~/ide/stores';
import * as actions from '~/ide/stores/modules/commit/actions';
import {
  COMMIT_TO_CURRENT_BRANCH,
  COMMIT_TO_NEW_BRANCH,
} from '~/ide/stores/modules/commit/constants';
import * as mutationTypes from '~/ide/stores/modules/commit/mutation_types';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const TEST_COMMIT_SHA = '123456789';
const COMMIT_RESPONSE = {
  id: '123456',
  short_id: '123',
  message: 'test message',
  committed_date: 'date',
  parent_ids: [],
  stats: {
    additions: '1',
    deletions: '2',
  },
};

describe('IDE commit module actions', () => {
  let mock;
  let store;
  let router;

  beforeEach(() => {
    store = createStore();
    router = createRouter(store);
    gon.api_version = 'v1';
    mock = new MockAdapter(axios);
    jest.spyOn(router, 'push').mockImplementation();

    mock
      .onGet('/api/v1/projects/abcproject/repository/branches/main')
      .reply(HTTP_STATUS_OK, { commit: COMMIT_RESPONSE });
  });

  afterEach(() => {
    mock.restore();
  });

  describe('updateCommitMessage', () => {
    it('updates store with new commit message', async () => {
      await store.dispatch('commit/updateCommitMessage', 'testing');
      expect(store.state.commit.commitMessage).toBe('testing');
    });
  });

  describe('discardDraft', () => {
    it('resets commit message to blank', async () => {
      store.state.commit.commitMessage = 'testing';

      await store.dispatch('commit/discardDraft');
      expect(store.state.commit.commitMessage).not.toBe('testing');
    });
  });

  describe('updateCommitAction', () => {
    it('updates store with new commit action', async () => {
      await store.dispatch('commit/updateCommitAction', '1');
      expect(store.state.commit.commitAction).toBe('1');
    });
  });

  describe('updateBranchName', () => {
    beforeEach(() => {
      window.gon.current_username = 'johndoe';

      store.state.currentBranchId = 'main';
    });

    it('updates store with new branch name', async () => {
      await store.dispatch('commit/updateBranchName', 'branch-name');

      expect(store.state.commit.newBranchName).toBe('branch-name');
    });
  });

  describe('addSuffixToBranchName', () => {
    it('adds suffix to branchName', async () => {
      jest.spyOn(Math, 'random').mockReturnValue(0.391352525);

      store.state.commit.newBranchName = 'branch-name';

      await store.dispatch('commit/addSuffixToBranchName');

      expect(store.state.commit.newBranchName).toBe('branch-name-39135');
    });
  });

  describe('setLastCommitMessage', () => {
    beforeEach(() => {
      Object.assign(store.state, {
        currentProjectId: 'abcproject',
        projects: {
          abcproject: {
            web_url: 'http://testing',
          },
        },
      });
    });

    it('updates commit message with short_id', async () => {
      await store.dispatch('commit/setLastCommitMessage', { short_id: '123' });
      expect(store.state.lastCommitMsg).toContain(
        'Your changes have been committed. Commit <a href="http://testing/-/commit/123" class="commit-sha">123</a>',
      );
    });

    it('updates commit message with stats', async () => {
      await store.dispatch('commit/setLastCommitMessage', {
        short_id: '123',
        stats: {
          additions: '1',
          deletions: '2',
        },
      });
      expect(store.state.lastCommitMsg).toBe(
        'Your changes have been committed. Commit <a href="http://testing/-/commit/123" class="commit-sha">123</a> with 1 additions, 2 deletions.',
      );
    });
  });

  describe('updateFilesAfterCommit', () => {
    const data = {
      id: '123',
      message: 'testing commit message',
      committed_date: '123',
      committer_name: 'root',
    };
    const branch = 'main';
    let f;

    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();

      f = file('changedFile');
      Object.assign(f, {
        active: true,
        changed: true,
        content: 'file content',
      });

      Object.assign(store.state, {
        currentProjectId: 'abcproject',
        currentBranchId: 'main',
        projects: {
          abcproject: {
            web_url: 'web_url',
            branches: {
              main: {
                workingReference: '',
                commit: {
                  short_id: TEST_COMMIT_SHA,
                },
              },
            },
          },
        },
        stagedFiles: [
          f,
          {
            ...file('changedFile2'),
            changed: true,
          },
        ],
      });

      store.state.openFiles = store.state.stagedFiles;
      store.state.stagedFiles.forEach((stagedFile) => {
        store.state.entries[stagedFile.path] = stagedFile;
      });
    });

    it('updates stores working reference', async () => {
      await store.dispatch('commit/updateFilesAfterCommit', {
        data,
        branch,
      });
      expect(store.state.projects.abcproject.branches.main.workingReference).toBe(data.id);
    });

    it('resets all files changed status', async () => {
      await store.dispatch('commit/updateFilesAfterCommit', {
        data,
        branch,
      });
      store.state.openFiles.forEach((entry) => {
        expect(entry.changed).toBe(false);
      });
    });

    it('sets files commit data', async () => {
      await store.dispatch('commit/updateFilesAfterCommit', {
        data,
        branch,
      });
      expect(f.lastCommitSha).toBe(data.id);
    });

    it('updates raw content for changed file', async () => {
      await store.dispatch('commit/updateFilesAfterCommit', {
        data,
        branch,
      });
      expect(f.raw).toBe(f.content);
    });

    it('emits changed event for file', async () => {
      await store.dispatch('commit/updateFilesAfterCommit', {
        data,
        branch,
      });
      expect(eventHub.$emit).toHaveBeenCalledWith(`editor.update.model.content.${f.key}`, {
        content: f.content,
        changed: false,
      });
    });
  });

  describe('commitChanges', () => {
    beforeEach(() => {
      document.body.innerHTML += '<div class="flash-container"></div>';

      const f = {
        ...file('changed'),
        type: 'blob',
        active: true,
        lastCommitSha: TEST_COMMIT_SHA,
        content: '\n',
        raw: '\n',
      };

      Object.assign(store.state, {
        stagedFiles: [f],
        changedFiles: [f],
        openFiles: [f],
        currentProjectId: 'abcproject',
        currentBranchId: 'main',
        projects: {
          abcproject: {
            default_branch: 'main',
            web_url: 'webUrl',
            branches: {
              main: {
                name: 'main',
                workingReference: '1',
                commit: {
                  id: TEST_COMMIT_SHA,
                },
                can_push: true,
              },
            },
            userPermissions: {
              [PERMISSION_CREATE_MR]: true,
            },
          },
        },
      });

      store.state.commit.commitAction = '2';
      store.state.commit.commitMessage = 'testing 123';

      store.state.openFiles.forEach((localF) => {
        store.state.entries[localF.path] = localF;
      });
    });

    afterEach(() => {
      document.querySelector('.flash-container').remove();
    });

    describe('success', () => {
      beforeEach(() => {
        jest.spyOn(service, 'commit').mockResolvedValue({ data: COMMIT_RESPONSE });
      });

      it('calls service', async () => {
        await store.dispatch('commit/commitChanges');
        expect(service.commit).toHaveBeenCalledWith('abcproject', {
          branch: expect.anything(),
          commit_message: 'testing 123',
          actions: [
            {
              action: commitActionTypes.update,
              file_path: expect.anything(),
              content: '\n',
              encoding: expect.anything(),
              last_commit_id: undefined,
              previous_path: undefined,
            },
          ],
          start_sha: TEST_COMMIT_SHA,
        });
      });

      it('sends lastCommit ID when not creating new branch', async () => {
        store.state.commit.commitAction = '1';

        await store.dispatch('commit/commitChanges');
        expect(service.commit).toHaveBeenCalledWith('abcproject', {
          branch: expect.anything(),
          commit_message: 'testing 123',
          actions: [
            {
              action: commitActionTypes.update,
              file_path: expect.anything(),
              content: '\n',
              encoding: expect.anything(),
              last_commit_id: TEST_COMMIT_SHA,
              previous_path: undefined,
            },
          ],
          start_sha: undefined,
        });
      });

      it('sets last Commit Msg', async () => {
        await store.dispatch('commit/commitChanges');
        expect(store.state.lastCommitMsg).toBe(
          'Your changes have been committed. Commit <a href="webUrl/-/commit/123" class="commit-sha">123</a> with 1 additions, 2 deletions.',
        );
      });

      it('adds commit data to files', async () => {
        await store.dispatch('commit/commitChanges');
        expect(store.state.entries[store.state.openFiles[0].path].lastCommitSha).toBe(
          COMMIT_RESPONSE.id,
        );
      });

      it('resets stores commit actions', async () => {
        store.state.commit.commitAction = COMMIT_TO_NEW_BRANCH;

        await store.dispatch('commit/commitChanges');
        expect(store.state.commit.commitAction).not.toBe(COMMIT_TO_NEW_BRANCH);
      });

      it('removes all staged files', async () => {
        await store.dispatch('commit/commitChanges');
        expect(store.state.stagedFiles.length).toBe(0);
      });

      describe('merge request', () => {
        it.each`
          branchName   | targetBranchName | branchNameInURL | targetBranchInURL
          ${'foo'}     | ${'main'}        | ${'foo'}        | ${'main'}
          ${'foo#bar'} | ${'main'}        | ${'foo%23bar'}  | ${'main'}
          ${'foo#bar'} | ${'not#so#main'} | ${'foo%23bar'}  | ${'not%23so%23main'}
        `(
          'redirects to the correct new MR page when new branch is "$branchName" and target branch is "$targetBranchName"',
          async ({ branchName, targetBranchName, branchNameInURL, targetBranchInURL }) => {
            Object.assign(store.state.projects.abcproject, {
              branches: {
                [targetBranchName]: {
                  name: targetBranchName,
                  workingReference: '1',
                  commit: {
                    id: TEST_COMMIT_SHA,
                  },
                  can_push: true,
                },
              },
            });
            store.state.currentBranchId = targetBranchName;
            store.state.commit.newBranchName = branchName;

            store.state.commit.commitAction = COMMIT_TO_NEW_BRANCH;
            store.state.commit.shouldCreateMR = true;

            await store.dispatch('commit/commitChanges');
            expect(visitUrl).toHaveBeenCalledWith(
              `webUrl/-/merge_requests/new?merge_request[source_branch]=${branchNameInURL}&merge_request[target_branch]=${targetBranchInURL}&nav_source=webide`,
            );
          },
        );

        it('does not redirect to new merge request page when shouldCreateMR is not checked', async () => {
          jest.spyOn(eventHub, '$on').mockImplementation();

          store.state.commit.commitAction = COMMIT_TO_NEW_BRANCH;
          store.state.commit.shouldCreateMR = false;

          await store.dispatch('commit/commitChanges');
          expect(visitUrl).not.toHaveBeenCalled();
        });

        it('does not redirect to merge request page if shouldCreateMR is checked, but branch is the default branch', async () => {
          jest.spyOn(eventHub, '$on').mockImplementation();

          store.state.commit.commitAction = COMMIT_TO_CURRENT_BRANCH;
          store.state.commit.shouldCreateMR = true;

          await store.dispatch('commit/commitChanges');
          expect(visitUrl).not.toHaveBeenCalled();
        });

        it('resets changed files before redirecting', () => {
          jest.spyOn(eventHub, '$on').mockImplementation();

          store.state.commit.commitAction = '3';

          return store.dispatch('commit/commitChanges').then(() => {
            expect(store.state.stagedFiles.length).toBe(0);
          });
        });
      });
    });

    describe('success response with failed message', () => {
      beforeEach(() => {
        jest.spyOn(service, 'commit').mockResolvedValue({
          data: {
            message: 'failed message',
          },
        });
      });

      it('shows failed message', async () => {
        await store.dispatch('commit/commitChanges');
        const alert = document.querySelector('.flash-container');

        expect(alert.textContent.trim()).toBe('failed message');
      });
    });

    describe('failed response', () => {
      beforeEach(() => {
        jest.spyOn(service, 'commit').mockRejectedValue({});
      });

      it('commits error updates', async () => {
        jest.spyOn(store, 'commit');

        await store.dispatch('commit/commitChanges').catch(() => {});

        expect(store.commit.mock.calls).toEqual([
          ['commit/CLEAR_ERROR', undefined, undefined],
          ['commit/UPDATE_LOADING', true, undefined],
          ['commit/UPDATE_LOADING', false, undefined],
          ['commit/SET_ERROR', createUnexpectedCommitError(), undefined],
        ]);
      });
    });

    describe('first commit of a branch', () => {
      it('commits TOGGLE_EMPTY_STATE mutation on empty repo', async () => {
        jest.spyOn(service, 'commit').mockResolvedValue({ data: COMMIT_RESPONSE });
        jest.spyOn(store, 'commit');

        await store.dispatch('commit/commitChanges');
        expect(store.commit.mock.calls).toEqual(
          expect.arrayContaining([['TOGGLE_EMPTY_STATE', expect.any(Object), expect.any(Object)]]),
        );
      });

      it('does not commmit TOGGLE_EMPTY_STATE mutation on existing project', async () => {
        COMMIT_RESPONSE.parent_ids.push('1234');
        jest.spyOn(service, 'commit').mockResolvedValue({ data: COMMIT_RESPONSE });
        jest.spyOn(store, 'commit');

        await store.dispatch('commit/commitChanges');
        expect(store.commit.mock.calls).not.toEqual(
          expect.arrayContaining([['TOGGLE_EMPTY_STATE', expect.any(Object), expect.any(Object)]]),
        );
      });
    });
  });

  describe('toggleShouldCreateMR', () => {
    it('commits both toggle and interacting with MR checkbox actions', () => {
      return testAction(
        actions.toggleShouldCreateMR,
        {},
        store.state,
        [{ type: mutationTypes.TOGGLE_SHOULD_CREATE_MR }],
        [],
      );
    });
  });
});
