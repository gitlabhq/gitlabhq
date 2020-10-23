import testAction from 'helpers/vuex_action_helper';
import createState from '~/milestones/stores/state';
import * as actions from '~/milestones/stores/actions';
import * as types from '~/milestones/stores/mutation_types';

let mockProjectMilestonesReturnValue;
let mockProjectSearchReturnValue;

jest.mock('~/api', () => ({
  // `__esModule: true` is required when mocking modules with default exports:
  // https://jestjs.io/docs/en/jest-object#jestmockmodulename-factory-options
  __esModule: true,
  default: {
    projectMilestones: () => mockProjectMilestonesReturnValue,
    projectSearch: () => mockProjectSearchReturnValue,
  },
}));

describe('Milestone combobox Vuex store actions', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('setProjectId', () => {
    it(`commits ${types.SET_PROJECT_ID} with the new project ID`, () => {
      const projectId = '4';
      testAction(actions.setProjectId, projectId, state, [
        { type: types.SET_PROJECT_ID, payload: projectId },
      ]);
    });
  });

  describe('setSelectedMilestones', () => {
    it(`commits ${types.SET_SELECTED_MILESTONES} with the new selected milestones name`, () => {
      const selectedMilestones = ['v1.2.3'];
      testAction(actions.setSelectedMilestones, selectedMilestones, state, [
        { type: types.SET_SELECTED_MILESTONES, payload: selectedMilestones },
      ]);
    });
  });

  describe('clearSelectedMilestones', () => {
    it(`commits ${types.CLEAR_SELECTED_MILESTONES} with the new selected milestones name`, () => {
      testAction(actions.clearSelectedMilestones, null, state, [
        { type: types.CLEAR_SELECTED_MILESTONES },
      ]);
    });
  });

  describe('toggleMilestones', () => {
    const selectedMilestone = 'v1.2.3';
    it(`commits ${types.ADD_SELECTED_MILESTONE} with the new selected milestone name`, () => {
      testAction(actions.toggleMilestones, selectedMilestone, state, [
        { type: types.ADD_SELECTED_MILESTONE, payload: selectedMilestone },
      ]);
    });

    it(`commits ${types.REMOVE_SELECTED_MILESTONE} with the new selected milestone name`, () => {
      state.selectedMilestones = [selectedMilestone];
      testAction(actions.toggleMilestones, selectedMilestone, state, [
        { type: types.REMOVE_SELECTED_MILESTONE, payload: selectedMilestone },
      ]);
    });
  });

  describe('search', () => {
    it(`commits ${types.SET_SEARCH_QUERY} with the new search query`, () => {
      const searchQuery = 'v1.0';
      testAction(
        actions.search,
        searchQuery,
        state,
        [{ type: types.SET_SEARCH_QUERY, payload: searchQuery }],
        [{ type: 'searchMilestones' }],
      );
    });
  });

  describe('searchMilestones', () => {
    describe('when the search is successful', () => {
      const projectSearchApiResponse = { data: [{ title: 'v1.0' }] };

      beforeEach(() => {
        mockProjectSearchReturnValue = Promise.resolve(projectSearchApiResponse);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_PROJECT_MILESTONES_SUCCESS} with the response from the API, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.searchMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_PROJECT_MILESTONES_SUCCESS, payload: projectSearchApiResponse },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });

    describe('when the search fails', () => {
      const error = new Error('Something went wrong!');

      beforeEach(() => {
        mockProjectSearchReturnValue = Promise.reject(error);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_PROJECT_MILESTONES_ERROR} with the error object, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.searchMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_PROJECT_MILESTONES_ERROR, payload: error },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });
  });

  describe('fetchMilestones', () => {
    describe('when the fetch is successful', () => {
      const projectMilestonesApiResponse = { data: [{ title: 'v1.0' }] };

      beforeEach(() => {
        mockProjectMilestonesReturnValue = Promise.resolve(projectMilestonesApiResponse);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_PROJECT_MILESTONES_SUCCESS} with the response from the API, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.fetchMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_PROJECT_MILESTONES_SUCCESS, payload: projectMilestonesApiResponse },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });

    describe('when the fetch fails', () => {
      const error = new Error('Something went wrong!');

      beforeEach(() => {
        mockProjectMilestonesReturnValue = Promise.reject(error);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_PROJECT_MILESTONES_ERROR} with the error object, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.fetchMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_PROJECT_MILESTONES_ERROR, payload: error },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });
  });
});
