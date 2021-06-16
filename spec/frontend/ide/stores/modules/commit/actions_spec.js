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
      .reply(200, { commit: COMMIT_RESPONSE });
  });

  afterEach(() => {
    delete gon.api_version;
    mock.restore();
  });

  describe('updateCommitMessage', () => {
    it('updates store with new commit message', (done) => {
      store
        .dispatch('commit/updateCommitMessage', 'testing')
        .then(() => {
          expect(store.state.commit.commitMessage).toBe('testing');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('discardDraft', () => {
    it('resets commit message to blank', (done) => {
      store.state.commit.commitMessage = 'testing';

      store
        .dispatch('commit/discardDraft')
        .then(() => {
          expect(store.state.commit.commitMessage).not.toBe('testing');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('updateCommitAction', () => {
    it('updates store with new commit action', (done) => {
      store
        .dispatch('commit/updateCommitAction', '1')
        .then(() => {
          expect(store.state.commit.commitAction).toBe('1');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('updateBranchName', () => {
    let originalGon;

    beforeEach(() => {
      originalGon = window.gon;
      window.gon = { current_username: 'johndoe' };

      store.state.currentBranchId = 'main';
    });

    afterEach(() => {
      window.gon = originalGon;
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

    it('updates commit message with short_id', (done) => {
      store
        .dispatch('commit/setLastCommitMessage', { short_id: '123' })
        .then(() => {
          expect(store.state.lastCommitMsg).toContain(
            'Your changes have been committed. Commit <a href="http://testing/-/commit/123" class="commit-sha">123</a>',
          );
        })
        .then(done)
        .catch(done.fail);
    });

    it('updates commit message with stats', (done) => {
      store
        .dispatch('commit/setLastCommitMessage', {
          short_id: '123',
          stats: {
            additions: '1',
            deletions: '2',
          },
        })
        .then(() => {
          expect(store.state.lastCommitMsg).toBe(
            'Your changes have been committed. Commit <a href="http://testing/-/commit/123" class="commit-sha">123</a> with 1 additions, 2 deletions.',
          );
        })
        .then(done)
        .catch(done.fail);
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

    it('updates stores working reference', (done) => {
      store
        .dispatch('commit/updateFilesAfterCommit', {
          data,
          branch,
        })
        .then(() => {
          expect(store.state.projects.abcproject.branches.main.workingReference).toBe(data.id);
        })
        .then(done)
        .catch(done.fail);
    });

    it('resets all files changed status', (done) => {
      store
        .dispatch('commit/updateFilesAfterCommit', {
          data,
          branch,
        })
        .then(() => {
          store.state.openFiles.forEach((entry) => {
            expect(entry.changed).toBeFalsy();
          });
        })
        .then(done)
        .catch(done.fail);
    });

    it('sets files commit data', (done) => {
      store
        .dispatch('commit/updateFilesAfterCommit', {
          data,
          branch,
        })
        .then(() => {
          expect(f.lastCommitSha).toBe(data.id);
        })
        .then(done)
        .catch(done.fail);
    });

    it('updates raw content for changed file', (done) => {
      store
        .dispatch('commit/updateFilesAfterCommit', {
          data,
          branch,
        })
        .then(() => {
          expect(f.raw).toBe(f.content);
        })
        .then(done)
        .catch(done.fail);
    });

    it('emits changed event for file', (done) => {
      store
        .dispatch('commit/updateFilesAfterCommit', {
          data,
          branch,
        })
        .then(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith(`editor.update.model.content.${f.key}`, {
            content: f.content,
            changed: false,
          });
        })
        .then(done)
        .catch(done.fail);
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

      it('calls service', (done) => {
        store
          .dispatch('commit/commitChanges')
          .then(() => {
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

            done();
          })
          .catch(done.fail);
      });

      it('sends lastCommit ID when not creating new branch', (done) => {
        store.state.commit.commitAction = '1';

        store
          .dispatch('commit/commitChanges')
          .then(() => {
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

            done();
          })
          .catch(done.fail);
      });

      it('sets last Commit Msg', (done) => {
        store
          .dispatch('commit/commitChanges')
          .then(() => {
            expect(store.state.lastCommitMsg).toBe(
              'Your changes have been committed. Commit <a href="webUrl/-/commit/123" class="commit-sha">123</a> with 1 additions, 2 deletions.',
            );

            done();
          })
          .catch(done.fail);
      });

      it('adds commit data to files', (done) => {
        store
          .dispatch('commit/commitChanges')
          .then(() => {
            expect(store.state.entries[store.state.openFiles[0].path].lastCommitSha).toBe(
              COMMIT_RESPONSE.id,
            );

            done();
          })
          .catch(done.fail);
      });

      it('resets stores commit actions', (done) => {
        store.state.commit.commitAction = COMMIT_TO_NEW_BRANCH;

        store
          .dispatch('commit/commitChanges')
          .then(() => {
            expect(store.state.commit.commitAction).not.toBe(COMMIT_TO_NEW_BRANCH);
          })
          .then(done)
          .catch(done.fail);
      });

      it('removes all staged files', (done) => {
        store
          .dispatch('commit/commitChanges')
          .then(() => {
            expect(store.state.stagedFiles.length).toBe(0);
          })
          .then(done)
          .catch(done.fail);
      });

      describe('merge request', () => {
        it('redirects to new merge request page', (done) => {
          jest.spyOn(eventHub, '$on').mockImplementation();

          store.state.commit.commitAction = COMMIT_TO_NEW_BRANCH;
          store.state.commit.shouldCreateMR = true;

          store
            .dispatch('commit/commitChanges')
            .then(() => {
              expect(visitUrl).toHaveBeenCalledWith(
                `webUrl/-/merge_requests/new?merge_request[source_branch]=${store.getters['commit/placeholderBranchName']}&merge_request[target_branch]=main&nav_source=webide`,
              );

              done();
            })
            .catch(done.fail);
        });

        it('does not redirect to new merge request page when shouldCreateMR is not checked', (done) => {
          jest.spyOn(eventHub, '$on').mockImplementation();

          store.state.commit.commitAction = COMMIT_TO_NEW_BRANCH;
          store.state.commit.shouldCreateMR = false;

          store
            .dispatch('commit/commitChanges')
            .then(() => {
              expect(visitUrl).not.toHaveBeenCalled();
              done();
            })
            .catch(done.fail);
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

      it('shows failed message', (done) => {
        store
          .dispatch('commit/commitChanges')
          .then(() => {
            const alert = document.querySelector('.flash-container');

            expect(alert.textContent.trim()).toBe('failed message');

            done();
          })
          .catch(done.fail);
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
      it('commits TOGGLE_EMPTY_STATE mutation on empty repo', (done) => {
        jest.spyOn(service, 'commit').mockResolvedValue({ data: COMMIT_RESPONSE });
        jest.spyOn(store, 'commit');

        store
          .dispatch('commit/commitChanges')
          .then(() => {
            expect(store.commit.mock.calls).toEqual(
              expect.arrayContaining([
                ['TOGGLE_EMPTY_STATE', expect.any(Object), expect.any(Object)],
              ]),
            );
            done();
          })
          .catch(done.fail);
      });

      it('does not commmit TOGGLE_EMPTY_STATE mutation on existing project', (done) => {
        COMMIT_RESPONSE.parent_ids.push('1234');
        jest.spyOn(service, 'commit').mockResolvedValue({ data: COMMIT_RESPONSE });
        jest.spyOn(store, 'commit');

        store
          .dispatch('commit/commitChanges')
          .then(() => {
            expect(store.commit.mock.calls).not.toEqual(
              expect.arrayContaining([
                ['TOGGLE_EMPTY_STATE', expect.any(Object), expect.any(Object)],
              ]),
            );
            done();
          })
          .catch(done.fail);
      });
    });
  });

  describe('toggleShouldCreateMR', () => {
    it('commits both toggle and interacting with MR checkbox actions', (done) => {
      testAction(
        actions.toggleShouldCreateMR,
        {},
        store.state,
        [{ type: mutationTypes.TOGGLE_SHOULD_CREATE_MR }],
        [],
        done,
      );
    });
  });
});
