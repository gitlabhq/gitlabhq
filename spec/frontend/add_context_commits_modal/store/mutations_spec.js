import getDiffWithCommit from 'test_fixtures/merge_request_diffs/with_commit.json';
import { TEST_HOST } from 'helpers/test_constants';
import * as types from '~/add_context_commits_modal/store/mutation_types';
import mutations from '~/add_context_commits_modal/store/mutations';

describe('AddContextCommitsModalStoreMutations', () => {
  const { commit } = getDiffWithCommit;
  describe('SET_BASE_CONFIG', () => {
    it('should set contextCommitsPath, mergeRequestIid and projectId', () => {
      const state = {};
      const contextCommitsPath = `${TEST_HOST}/gitlab-org/gitlab/-/merge_requests/1/context_commits.json`;
      const mergeRequestIid = 1;
      const projectId = 1;

      mutations[types.SET_BASE_CONFIG](state, { contextCommitsPath, mergeRequestIid, projectId });

      expect(state.contextCommitsPath).toEqual(contextCommitsPath);
      expect(state.mergeRequestIid).toEqual(mergeRequestIid);
      expect(state.projectId).toEqual(projectId);
    });
  });

  describe('SET_TABINDEX', () => {
    it('sets tabIndex to specific index', () => {
      const state = { tabIndex: 0 };

      mutations[types.SET_TABINDEX](state, 1);

      expect(state.tabIndex).toBe(1);
    });
  });

  describe('FETCH_COMMITS', () => {
    it('sets isLoadingCommits to true', () => {
      const state = { isLoadingCommits: false };

      mutations[types.FETCH_COMMITS](state);

      expect(state.isLoadingCommits).toBe(true);
    });
  });

  describe('SET_COMMITS', () => {
    it('sets commits to passed data and stop loading', () => {
      const state = { commits: [], isLoadingCommits: true };

      mutations[types.SET_COMMITS](state, [commit]);

      expect(state.commits).toStrictEqual([commit]);
      expect(state.isLoadingCommits).toBe(false);
    });
  });

  describe('SET_COMMITS_SILENT', () => {
    it('sets commits to passed data and loading continues', () => {
      const state = { commits: [], isLoadingCommits: true };

      mutations[types.SET_COMMITS_SILENT](state, [commit]);

      expect(state.commits).toStrictEqual([commit]);
      expect(state.isLoadingCommits).toBe(true);
    });
  });

  describe('FETCH_COMMITS_ERROR', () => {
    it('sets commitsLoadingError to true', () => {
      const state = { commitsLoadingError: false };

      mutations[types.FETCH_COMMITS_ERROR](state);

      expect(state.commitsLoadingError).toBe(true);
    });
  });

  describe('FETCH_CONTEXT_COMMITS', () => {
    it('sets isLoadingContextCommits to true', () => {
      const state = { isLoadingContextCommits: false };

      mutations[types.FETCH_CONTEXT_COMMITS](state);

      expect(state.isLoadingContextCommits).toBe(true);
    });
  });

  describe('SET_CONTEXT_COMMITS', () => {
    it('sets contextCommit to passed data and stop loading', () => {
      const state = { contextCommits: [], isLoadingContextCommits: true };

      mutations[types.SET_CONTEXT_COMMITS](state, [commit]);

      expect(state.contextCommits).toStrictEqual([commit]);
      expect(state.isLoadingContextCommits).toBe(false);
    });
  });

  describe('FETCH_CONTEXT_COMMITS_ERROR', () => {
    it('sets contextCommitsLoadingError to true', () => {
      const state = { contextCommitsLoadingError: false };

      mutations[types.FETCH_CONTEXT_COMMITS_ERROR](state);

      expect(state.contextCommitsLoadingError).toBe(true);
    });
  });

  describe('SET_SELECTED_COMMITS', () => {
    it('sets selectedCommits to specified value', () => {
      const state = { selectedCommits: [] };

      mutations[types.SET_SELECTED_COMMITS](state, [commit]);

      expect(state.selectedCommits).toStrictEqual([commit]);
    });
  });

  describe('SET_SEARCH_TEXT', () => {
    it('sets searchText to specified value', () => {
      const searchText = 'Test';
      const state = { searchText: '' };

      mutations[types.SET_SEARCH_TEXT](state, searchText);

      expect(state.searchText).toBe(searchText);
    });
  });

  describe('SET_TO_REMOVE_COMMITS', () => {
    it('sets searchText to specified value', () => {
      const state = { toRemoveCommits: [] };

      mutations[types.SET_TO_REMOVE_COMMITS](state, [commit.short_id]);

      expect(state.toRemoveCommits).toStrictEqual([commit.short_id]);
    });
  });

  describe('RESET_MODAL_STATE', () => {
    it('sets searchText to specified value', () => {
      const state = {
        commits: [commit],
        contextCommits: [commit],
        selectedCommits: [commit],
        toRemoveCommits: [commit.short_id],
        searchText: 'Test',
      };

      mutations[types.RESET_MODAL_STATE](state);

      expect(state.commits).toStrictEqual([]);
      expect(state.contextCommits).toStrictEqual([]);
      expect(state.selectedCommits).toStrictEqual([]);
      expect(state.toRemoveCommits).toStrictEqual([]);
      expect(state.searchText).toBe('');
    });
  });
});
