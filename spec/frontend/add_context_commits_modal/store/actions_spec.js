import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
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
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NO_CONTENT, HTTP_STATUS_OK } from '~/lib/utils/http_status';

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
  let mock;

  beforeEach(() => {
    gon.api_version = 'v4';
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setBaseConfig', () => {
    it('commits SET_BASE_CONFIG', () => {
      const options = { contextCommitsPath, mergeRequestIid, projectId };
      return testAction(
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
      );
    });
  });

  describe('setTabIndex', () => {
    it('commits SET_TABINDEX', () => {
      return testAction(
        setTabIndex,
        { tabIndex: 1 },
        { tabIndex: 0 },
        [{ type: types.SET_TABINDEX, payload: { tabIndex: 1 } }],
        [],
      );
    });
  });

  describe('setCommits', () => {
    it('commits SET_COMMITS', () => {
      return testAction(
        setCommits,
        { commits: [], silentAddition: false },
        { isLoadingCommits: false, commits: [] },
        [{ type: types.SET_COMMITS, payload: [] }],
        [],
      );
    });

    it('commits SET_COMMITS_SILENT', () => {
      return testAction(
        setCommits,
        { commits: [], silentAddition: true },
        { isLoadingCommits: true, commits: [] },
        [{ type: types.SET_COMMITS_SILENT, payload: [] }],
        [],
      );
    });
  });

  describe('createContextCommits', () => {
    it('calls API to create context commits', async () => {
      mock.onPost(contextCommitEndpoint).reply(HTTP_STATUS_OK, {});

      await testAction(createContextCommits, { commits: [] }, {}, [], []);

      await createContextCommits(
        { state: { projectId, mergeRequestIid }, commit: () => null },
        { commits: [] },
      );
    });
  });

  describe('fetchContextCommits', () => {
    beforeEach(() => {
      mock
        .onGet(
          `/api/${gon.api_version}/projects/gitlab-org%2Fgitlab/merge_requests/1/context_commits`,
        )
        .reply(HTTP_STATUS_OK, [dummyCommit]);
    });
    it('commits FETCH_CONTEXT_COMMITS', () => {
      const contextCommit = { ...dummyCommit, isSelected: true };
      return testAction(
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
      );
    });
  });

  describe('setContextCommits', () => {
    it('commits SET_CONTEXT_COMMITS', () => {
      return testAction(
        setContextCommits,
        { data: [] },
        { contextCommits: [], isLoadingContextCommits: false },
        [{ type: types.SET_CONTEXT_COMMITS, payload: { data: [] } }],
        [],
      );
    });
  });

  describe('removeContextCommits', () => {
    beforeEach(() => {
      mock
        .onDelete('/api/v4/projects/gitlab-org%2Fgitlab/merge_requests/1/context_commits')
        .reply(HTTP_STATUS_NO_CONTENT);
    });
    it('calls API to remove context commits', () => {
      return testAction(
        removeContextCommits,
        { forceReload: false },
        { mergeRequestIid, projectId, toRemoveCommits: [] },
        [],
        [],
      );
    });
  });

  describe('setSelectedCommits', () => {
    it('commits SET_SELECTED_COMMITS', () => {
      return testAction(
        setSelectedCommits,
        [dummyCommit],
        { selectedCommits: [] },
        [{ type: types.SET_SELECTED_COMMITS, payload: [dummyCommit] }],
        [],
      );
    });
  });

  describe('setSearchText', () => {
    it('commits SET_SEARCH_TEXT', () => {
      const searchText = 'Dummy Text';
      return testAction(
        setSearchText,
        searchText,
        { searchText: '' },
        [{ type: types.SET_SEARCH_TEXT, payload: searchText }],
        [],
      );
    });
  });

  describe('setToRemoveCommits', () => {
    it('commits SET_TO_REMOVE_COMMITS', () => {
      const commitId = 'abcde';

      return testAction(
        setToRemoveCommits,
        [commitId],
        { toRemoveCommits: [] },
        [{ type: types.SET_TO_REMOVE_COMMITS, payload: [commitId] }],
        [],
      );
    });
  });

  describe('resetModalState', () => {
    it('commits RESET_MODAL_STATE', () => {
      const commitId = 'abcde';

      return testAction(
        resetModalState,
        null,
        { toRemoveCommits: [commitId] },
        [{ type: types.RESET_MODAL_STATE }],
        [],
      );
    });
  });
});
