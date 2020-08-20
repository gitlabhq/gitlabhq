import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import {
  setBaseConfig,
  setTabIndex,
  setCommits,
  createContextCommits,
  fetchContextCommits,
  setContextCommits,
  removeContextCommits,
  setSelectedCommits,
  setSearchText,
  setToRemoveCommits,
  resetModalState,
} from '~/add_context_commits_modal/store/actions';
import * as types from '~/add_context_commits_modal/store/mutation_types';
import testAction from '../../helpers/vuex_action_helper';

describe('AddContextCommitsModalStoreActions', () => {
  const contextCommitEndpoint =
    '/api/v4/projects/gitlab-org%2fgitlab/merge_requests/1/context_commits';
  const mergeRequestIid = 1;
  const projectId = 1;
  const projectPath = 'gitlab-org/gitlab';
  const contextCommitsPath = `${TEST_HOST}/gitlab-org/gitlab/-/merge_requests/1/context_commits.json`;
  const dummyCommit = {
    id: 1,
    title: 'dummy commit',
    short_id: 'abcdef',
    committed_date: '2020-06-12',
  };
  gon.api_version = 'v4';
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setBaseConfig', () => {
    it('commits SET_BASE_CONFIG', done => {
      const options = { contextCommitsPath, mergeRequestIid, projectId };
      testAction(
        setBaseConfig,
        options,
        {
          contextCommitsPath: '',
          mergeRequestIid,
          projectId,
        },
        [
          {
            type: types.SET_BASE_CONFIG,
            payload: options,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setTabIndex', () => {
    it('commits SET_TABINDEX', done => {
      testAction(
        setTabIndex,
        { tabIndex: 1 },
        { tabIndex: 0 },
        [{ type: types.SET_TABINDEX, payload: { tabIndex: 1 } }],
        [],
        done,
      );
    });
  });

  describe('setCommits', () => {
    it('commits SET_COMMITS', done => {
      testAction(
        setCommits,
        { commits: [], silentAddition: false },
        { isLoadingCommits: false, commits: [] },
        [{ type: types.SET_COMMITS, payload: [] }],
        [],
        done,
      );
    });

    it('commits SET_COMMITS_SILENT', done => {
      testAction(
        setCommits,
        { commits: [], silentAddition: true },
        { isLoadingCommits: true, commits: [] },
        [{ type: types.SET_COMMITS_SILENT, payload: [] }],
        [],
        done,
      );
    });
  });

  describe('createContextCommits', () => {
    it('calls API to create context commits', done => {
      mock.onPost(contextCommitEndpoint).reply(200, {});

      testAction(createContextCommits, { commits: [] }, {}, [], [], done);

      createContextCommits(
        { state: { projectId, mergeRequestIid }, commit: () => null },
        { commits: [] },
      )
        .then(() => {
          done();
        })
        .catch(done.fail);
    });
  });

  describe('fetchContextCommits', () => {
    beforeEach(() => {
      mock
        .onGet(
          `/api/${gon.api_version}/projects/gitlab-org%2Fgitlab/merge_requests/1/context_commits`,
        )
        .reply(200, [dummyCommit]);
    });
    it('commits FETCH_CONTEXT_COMMITS', done => {
      const contextCommit = { ...dummyCommit, isSelected: true };
      testAction(
        fetchContextCommits,
        null,
        {
          mergeRequestIid,
          projectId: projectPath,
          isLoadingContextCommits: false,
          contextCommitsLoadingError: false,
          commits: [],
        },
        [{ type: types.FETCH_CONTEXT_COMMITS }],
        [
          { type: 'setContextCommits', payload: [contextCommit] },
          { type: 'setCommits', payload: { commits: [contextCommit], silentAddition: true } },
          { type: 'setSelectedCommits', payload: [contextCommit] },
        ],
        done,
      );
    });
  });

  describe('setContextCommits', () => {
    it('commits SET_CONTEXT_COMMITS', done => {
      testAction(
        setContextCommits,
        { data: [] },
        { contextCommits: [], isLoadingContextCommits: false },
        [{ type: types.SET_CONTEXT_COMMITS, payload: { data: [] } }],
        [],
        done,
      );
    });
  });

  describe('removeContextCommits', () => {
    beforeEach(() => {
      mock
        .onDelete('/api/v4/projects/gitlab-org%2Fgitlab/merge_requests/1/context_commits')
        .reply(204);
    });
    it('calls API to remove context commits', done => {
      testAction(
        removeContextCommits,
        { forceReload: false },
        { mergeRequestIid, projectId, toRemoveCommits: [] },
        [],
        [],
        done,
      );
    });
  });

  describe('setSelectedCommits', () => {
    it('commits SET_SELECTED_COMMITS', done => {
      testAction(
        setSelectedCommits,
        [dummyCommit],
        { selectedCommits: [] },
        [{ type: types.SET_SELECTED_COMMITS, payload: [dummyCommit] }],
        [],
        done,
      );
    });
  });

  describe('setSearchText', () => {
    it('commits SET_SEARCH_TEXT', done => {
      const searchText = 'Dummy Text';
      testAction(
        setSearchText,
        searchText,
        { searchText: '' },
        [{ type: types.SET_SEARCH_TEXT, payload: searchText }],
        [],
        done,
      );
    });
  });

  describe('setToRemoveCommits', () => {
    it('commits SET_TO_REMOVE_COMMITS', done => {
      const commitId = 'abcde';

      testAction(
        setToRemoveCommits,
        [commitId],
        { toRemoveCommits: [] },
        [{ type: types.SET_TO_REMOVE_COMMITS, payload: [commitId] }],
        [],
        done,
      );
    });
  });

  describe('resetModalState', () => {
    it('commits RESET_MODAL_STATE', done => {
      const commitId = 'abcde';

      testAction(
        resetModalState,
        null,
        { toRemoveCommits: [commitId] },
        [{ type: types.RESET_MODAL_STATE }],
        [],
        done,
      );
    });
  });
});
