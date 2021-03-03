import testAction from 'helpers/vuex_action_helper';
import { ALL_REF_TYPES, REF_TYPE_BRANCHES, REF_TYPE_TAGS, REF_TYPE_COMMITS } from '~/ref/constants';
import * as actions from '~/ref/stores/actions';
import * as types from '~/ref/stores/mutation_types';
import createState from '~/ref/stores/state';

let mockBranchesReturnValue;
let mockTagsReturnValue;
let mockCommitReturnValue;

jest.mock('~/api', () => ({
  // `__esModule: true` is required when mocking modules with default exports:
  // https://jestjs.io/docs/en/jest-object#jestmockmodulename-factory-options
  __esModule: true,
  default: {
    branches: () => mockBranchesReturnValue,
    tags: () => mockTagsReturnValue,
    commit: () => mockCommitReturnValue,
  },
}));

describe('Ref selector Vuex store actions', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('setEnabledRefTypes', () => {
    it(`commits ${types.SET_ENABLED_REF_TYPES} with the enabled ref types`, () => {
      testAction(actions.setProjectId, ALL_REF_TYPES, state, [
        { type: types.SET_PROJECT_ID, payload: ALL_REF_TYPES },
      ]);
    });
  });

  describe('setProjectId', () => {
    it(`commits ${types.SET_PROJECT_ID} with the new project ID`, () => {
      const projectId = '4';
      testAction(actions.setProjectId, projectId, state, [
        { type: types.SET_PROJECT_ID, payload: projectId },
      ]);
    });
  });

  describe('setSelectedRef', () => {
    it(`commits ${types.SET_SELECTED_REF} with the new selected ref name`, () => {
      const selectedRef = 'v1.2.3';
      testAction(actions.setSelectedRef, selectedRef, state, [
        { type: types.SET_SELECTED_REF, payload: selectedRef },
      ]);
    });
  });

  describe('search', () => {
    it(`commits ${types.SET_QUERY} with the new search query`, () => {
      const query = 'hello';
      testAction(actions.search, query, state, [{ type: types.SET_QUERY, payload: query }]);
    });

    it.each`
      enabledRefTypes                                         | expectedActions
      ${[REF_TYPE_BRANCHES]}                                  | ${['searchBranches']}
      ${[REF_TYPE_COMMITS]}                                   | ${['searchCommits']}
      ${[REF_TYPE_BRANCHES, REF_TYPE_TAGS, REF_TYPE_COMMITS]} | ${['searchBranches', 'searchTags', 'searchCommits']}
    `(`dispatches fetch actions for enabled ref types`, ({ enabledRefTypes, expectedActions }) => {
      const query = 'hello';
      state.enabledRefTypes = enabledRefTypes;
      testAction(
        actions.search,
        query,
        state,
        [{ type: types.SET_QUERY, payload: query }],
        expectedActions.map((type) => ({ type })),
      );
    });
  });

  describe('searchBranches', () => {
    describe('when the search is successful', () => {
      const branchesApiResponse = { data: [{ name: 'my-feature-branch' }] };

      beforeEach(() => {
        mockBranchesReturnValue = Promise.resolve(branchesApiResponse);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_BRANCHES_SUCCESS} with the response from the API, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.searchBranches, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_BRANCHES_SUCCESS, payload: branchesApiResponse },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });

    describe('when the search fails', () => {
      const error = new Error('Something went wrong!');

      beforeEach(() => {
        mockBranchesReturnValue = Promise.reject(error);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_BRANCHES_ERROR} with the error object, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.searchBranches, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_BRANCHES_ERROR, payload: error },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });
  });

  describe('searchTags', () => {
    describe('when the search is successful', () => {
      const tagsApiResponse = { data: [{ name: 'v1.2.3' }] };

      beforeEach(() => {
        mockTagsReturnValue = Promise.resolve(tagsApiResponse);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_TAGS_SUCCESS} with the response from the API, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.searchTags, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_TAGS_SUCCESS, payload: tagsApiResponse },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });

    describe('when the search fails', () => {
      const error = new Error('Something went wrong!');

      beforeEach(() => {
        mockTagsReturnValue = Promise.reject(error);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_TAGS_ERROR} with the error object, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.searchTags, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_TAGS_ERROR, payload: error },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });
  });

  describe('searchCommits', () => {
    describe('when the search query potentially matches a commit SHA', () => {
      beforeEach(() => {
        state.isQueryPossiblyASha = true;
      });

      describe('when the search is successful', () => {
        const commitApiResponse = { data: [{ id: 'abcd1234' }] };

        beforeEach(() => {
          mockCommitReturnValue = Promise.resolve(commitApiResponse);
        });

        it(`commits ${types.REQUEST_START}, ${types.RECEIVE_COMMITS_SUCCESS} with the response from the API, and ${types.REQUEST_FINISH}`, () => {
          return testAction(actions.searchCommits, undefined, state, [
            { type: types.REQUEST_START },
            { type: types.RECEIVE_COMMITS_SUCCESS, payload: commitApiResponse },
            { type: types.REQUEST_FINISH },
          ]);
        });
      });

      describe('when the search fails', () => {
        const error = new Error('Something went wrong!');

        beforeEach(() => {
          mockCommitReturnValue = Promise.reject(error);
        });

        describe('when the search query might match a commit SHA', () => {
          it(`commits ${types.REQUEST_START}, ${types.RECEIVE_COMMITS_ERROR} with the error object, and ${types.REQUEST_FINISH}`, () => {
            return testAction(actions.searchCommits, undefined, state, [
              { type: types.REQUEST_START },
              { type: types.RECEIVE_COMMITS_ERROR, payload: error },
              { type: types.REQUEST_FINISH },
            ]);
          });
        });
      });
    });

    describe('when the search query will not match a commit SHA', () => {
      beforeEach(() => {
        state.isQueryPossiblyASha = false;
      });

      it(`commits ${types.RESET_COMMIT_MATCHES}`, () => {
        return testAction(actions.searchCommits, undefined, state, [
          { type: types.RESET_COMMIT_MATCHES },
        ]);
      });
    });
  });
});
