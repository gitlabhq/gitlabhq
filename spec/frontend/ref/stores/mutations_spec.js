import { X_TOTAL_HEADER, ALL_REF_TYPES } from '~/ref/constants';
import * as types from '~/ref/stores/mutation_types';
import mutations from '~/ref/stores/mutations';
import createState from '~/ref/stores/state';

describe('Ref selector Vuex store mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('initial state', () => {
    it('is created with the correct structure and initial values', () => {
      expect(state).toEqual({
        enabledRefTypes: [],
        projectId: null,

        query: '',
        matches: {
          branches: {
            list: [],
            totalCount: 0,
            error: null,
          },
          tags: {
            list: [],
            totalCount: 0,
            error: null,
          },
          commits: {
            list: [],
            totalCount: 0,
            error: null,
          },
        },
        params: null,
        selectedRef: null,
        requestCount: 0,
      });
    });
  });

  describe(`${types.SET_ENABLED_REF_TYPES}`, () => {
    it('sets the enabled ref types', () => {
      mutations[types.SET_ENABLED_REF_TYPES](state, ALL_REF_TYPES);

      expect(state.enabledRefTypes).toBe(ALL_REF_TYPES);
    });
  });

  describe(`${types.SET_USE_SYMBOLIC_REF_NAMES}`, () => {
    it('sets useSymbolicRefNames on the state', () => {
      mutations[types.SET_USE_SYMBOLIC_REF_NAMES](state, true);

      expect(state.useSymbolicRefNames).toBe(true);
    });
  });

  describe(`${types.SET_PARAMS}`, () => {
    it('sets the additional query params', () => {
      const params = { sort: 'updated_desc' };
      mutations[types.SET_PARAMS](state, params);

      expect(state.params).toBe(params);
    });
  });

  describe(`${types.SET_PROJECT_ID}`, () => {
    it('updates the project ID', () => {
      const newProjectId = '4';
      mutations[types.SET_PROJECT_ID](state, newProjectId);

      expect(state.projectId).toBe(newProjectId);
    });
  });

  describe(`${types.SET_SELECTED_REF}`, () => {
    it('updates the selected ref', () => {
      const newSelectedRef = 'my-feature-branch';
      mutations[types.SET_SELECTED_REF](state, newSelectedRef);

      expect(state.selectedRef).toBe(newSelectedRef);
    });
  });

  describe(`${types.SET_QUERY}`, () => {
    it('updates the search query', () => {
      const newQuery = 'hello';
      mutations[types.SET_QUERY](state, newQuery);

      expect(state.query).toBe(newQuery);
    });
  });

  describe(`${types.REQUEST_START}`, () => {
    it('increments requestCount by 1', () => {
      mutations[types.REQUEST_START](state);
      expect(state.requestCount).toBe(1);

      mutations[types.REQUEST_START](state);
      expect(state.requestCount).toBe(2);

      mutations[types.REQUEST_START](state);
      expect(state.requestCount).toBe(3);
    });
  });

  describe(`${types.REQUEST_FINISH}`, () => {
    it('decrements requestCount by 1', () => {
      state.requestCount = 3;

      mutations[types.REQUEST_FINISH](state);
      expect(state.requestCount).toBe(2);

      mutations[types.REQUEST_FINISH](state);
      expect(state.requestCount).toBe(1);

      mutations[types.REQUEST_FINISH](state);
      expect(state.requestCount).toBe(0);
    });
  });

  describe(`${types.RECEIVE_BRANCHES_SUCCESS}`, () => {
    it('updates state.matches.branches based on the provided API response', () => {
      const response = {
        data: [
          {
            name: 'main',
            default: true,

            // everything except "name" and "default" should be stripped
            merged: false,
            protected: true,
          },
          {
            name: 'my-feature-branch',
            default: false,
          },
        ],
        headers: {
          [X_TOTAL_HEADER]: 37,
        },
      };

      mutations[types.RECEIVE_BRANCHES_SUCCESS](state, response);

      expect(state.matches.branches).toEqual({
        list: [
          {
            name: 'main',
            default: true,
            protected: true,
          },
          {
            name: 'my-feature-branch',
            default: false,
          },
        ],
        totalCount: 37,
        error: null,
      });
    });
  });

  describe(`${types.RECEIVE_BRANCHES_ERROR}`, () => {
    it('updates state.matches.branches to an empty state with the error object', () => {
      const error = new Error('Something went wrong!');

      state.matches.branches = {
        list: [{ name: 'my-feature-branch' }],
        totalCount: 1,
        error: null,
      };

      mutations[types.RECEIVE_BRANCHES_ERROR](state, error);

      expect(state.matches.branches).toEqual({
        list: [],
        totalCount: 0,
        error,
      });
    });
  });

  describe(`${types.RECEIVE_REQUEST_TAGS_SUCCESS}`, () => {
    it('updates state.matches.tags based on the provided API response', () => {
      const response = {
        data: [
          {
            name: 'v1.2',

            // everything except "name" should be stripped
            target: '2695effb5807a22ff3d138d593fd856244e155e7',
          },
        ],
        headers: {
          [X_TOTAL_HEADER]: 23,
        },
      };

      mutations[types.RECEIVE_TAGS_SUCCESS](state, response);

      expect(state.matches.tags).toEqual({
        list: [
          {
            name: 'v1.2',
          },
        ],
        totalCount: 23,
        error: null,
      });
    });
  });

  describe(`${types.RECEIVE_TAGS_ERROR}`, () => {
    it('updates state.matches.tags to an empty state with the error object', () => {
      const error = new Error('Something went wrong!');

      state.matches.tags = {
        list: [{ name: 'v1.2' }],
        totalCount: 1,
        error: null,
      };

      mutations[types.RECEIVE_TAGS_ERROR](state, error);

      expect(state.matches.tags).toEqual({
        list: [],
        totalCount: 0,
        error,
      });
    });
  });

  describe(`${types.RECEIVE_COMMITS_SUCCESS}`, () => {
    it('updates state.matches.commits based on the provided API response', () => {
      const response = {
        data: {
          id: '2695effb5807a22ff3d138d593fd856244e155e7',
          short_id: '2695effb580',
          title: 'Initial commit',

          // everything except "id", "short_id", and "title" should be stripped
          author_name: 'Example User',
        },
      };

      mutations[types.RECEIVE_COMMITS_SUCCESS](state, response);

      expect(state.matches.commits).toEqual({
        list: [
          {
            name: '2695effb580',
            value: '2695effb5807a22ff3d138d593fd856244e155e7',
            subtitle: 'Initial commit',
          },
        ],
        totalCount: 1,
        error: null,
      });
    });
  });

  describe(`${types.RECEIVE_COMMITS_ERROR}`, () => {
    it('updates state.matches.commits to an empty state with the error object', () => {
      const error = new Error('Something went wrong!');

      state.matches.commits = {
        list: [{ name: 'abcd0123' }],
        totalCount: 1,
        error: null,
      };

      mutations[types.RECEIVE_COMMITS_ERROR](state, error);

      expect(state.matches.commits).toEqual({
        list: [],
        totalCount: 0,
        error,
      });
    });
  });

  describe(`${types.RESET_COMMIT_MATCHES}`, () => {
    it('resets the commit results back to their original (empty) state', () => {
      state.matches.commits = {
        list: [{ name: 'abcd0123' }],
        totalCount: 1,
        error: null,
      };

      mutations[types.RESET_COMMIT_MATCHES](state);

      expect(state.matches.commits).toEqual({
        list: [],
        totalCount: 0,
        error: null,
      });
    });
  });
});
