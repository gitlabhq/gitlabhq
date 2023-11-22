import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/milestones/stores/actions';
import * as types from '~/milestones/stores/mutation_types';
import createState from '~/milestones/stores/state';

let mockProjectMilestonesReturnValue;
let mockGroupMilestonesReturnValue;
let mockProjectSearchReturnValue;

jest.mock('~/api', () => ({
  // `__esModule: true` is required when mocking modules with default exports:
  // https://jestjs.io/docs/en/jest-object#jestmockmodulename-factory-options
  __esModule: true,
  default: {
    projectMilestones: () => mockProjectMilestonesReturnValue,
    projectSearch: () => mockProjectSearchReturnValue,
    groupMilestones: () => mockGroupMilestonesReturnValue,
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
      return testAction(actions.setProjectId, projectId, state, [
        { type: types.SET_PROJECT_ID, payload: projectId },
      ]);
    });
  });

  describe('setGroupId', () => {
    it(`commits ${types.SET_GROUP_ID} with the new group ID`, () => {
      const groupId = '123';
      return testAction(actions.setGroupId, groupId, state, [
        { type: types.SET_GROUP_ID, payload: groupId },
      ]);
    });
  });

  describe('setGroupMilestonesAvailable', () => {
    it(`commits ${types.SET_GROUP_MILESTONES_AVAILABLE} with the boolean indicating if group milestones are available (Premium)`, () => {
      state.groupMilestonesAvailable = true;
      return testAction(
        actions.setGroupMilestonesAvailable,
        state.groupMilestonesAvailable,
        state,
        [{ type: types.SET_GROUP_MILESTONES_AVAILABLE, payload: state.groupMilestonesAvailable }],
      );
    });
  });

  describe('setSelectedMilestones', () => {
    it(`commits ${types.SET_SELECTED_MILESTONES} with the new selected milestones name`, () => {
      const selectedMilestones = ['v1.2.3'];
      return testAction(actions.setSelectedMilestones, selectedMilestones, state, [
        { type: types.SET_SELECTED_MILESTONES, payload: selectedMilestones },
      ]);
    });
  });

  describe('clearSelectedMilestones', () => {
    it(`commits ${types.CLEAR_SELECTED_MILESTONES} with the new selected milestones name`, () => {
      return testAction(actions.clearSelectedMilestones, null, state, [
        { type: types.CLEAR_SELECTED_MILESTONES },
      ]);
    });
  });

  describe('toggleMilestones', () => {
    const selectedMilestone = 'v1.2.3';
    it(`commits ${types.ADD_SELECTED_MILESTONE} with the new selected milestone name`, () => {
      return testAction(actions.toggleMilestones, selectedMilestone, state, [
        { type: types.ADD_SELECTED_MILESTONE, payload: selectedMilestone },
      ]);
    });

    it(`commits ${types.REMOVE_SELECTED_MILESTONE} with the new selected milestone name`, () => {
      state.selectedMilestones = [selectedMilestone];
      return testAction(actions.toggleMilestones, selectedMilestone, state, [
        { type: types.REMOVE_SELECTED_MILESTONE, payload: selectedMilestone },
      ]);
    });
  });

  describe('search', () => {
    describe('when project has license to add group milestones', () => {
      it(`commits ${types.SET_SEARCH_QUERY} with the new search query to search for project and group milestones`, () => {
        const getters = {
          groupMilestonesEnabled: () => true,
        };

        const searchQuery = 'v1.0';
        return testAction(
          actions.search,
          searchQuery,
          { ...state, ...getters },
          [{ type: types.SET_SEARCH_QUERY, payload: searchQuery }],
          [{ type: 'searchProjectMilestones' }, { type: 'searchGroupMilestones' }],
        );
      });
    });

    describe('when project does not have license to add group milestones', () => {
      it(`commits ${types.SET_SEARCH_QUERY} with the new search query to search for project milestones`, () => {
        const searchQuery = 'v1.0';
        return testAction(
          actions.search,
          searchQuery,
          state,
          [{ type: types.SET_SEARCH_QUERY, payload: searchQuery }],
          [{ type: 'searchProjectMilestones' }],
        );
      });
    });
  });

  describe('searchProjectMilestones', () => {
    describe('when the search is successful', () => {
      const projectSearchApiResponse = { data: [{ title: 'v1.0' }] };

      beforeEach(() => {
        mockProjectSearchReturnValue = Promise.resolve(projectSearchApiResponse);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_PROJECT_MILESTONES_SUCCESS} with the response from the API, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.searchProjectMilestones, undefined, state, [
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
        return testAction(actions.searchProjectMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_PROJECT_MILESTONES_ERROR, payload: error },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });
  });

  describe('searchGroupMilestones', () => {
    describe('when the search is successful', () => {
      const groupSearchApiResponse = { data: [{ title: 'group-v1.0' }] };

      beforeEach(() => {
        mockGroupMilestonesReturnValue = Promise.resolve(groupSearchApiResponse);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_GROUP_MILESTONES_SUCCESS} with the response from the API, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.searchGroupMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_GROUP_MILESTONES_SUCCESS, payload: groupSearchApiResponse },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });

    describe('when the search fails', () => {
      const error = new Error('Something went wrong!');

      beforeEach(() => {
        mockGroupMilestonesReturnValue = Promise.reject(error);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_GROUP_MILESTONES_ERROR} with the error object, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.searchGroupMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_GROUP_MILESTONES_ERROR, payload: error },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });
  });

  describe('fetchMilestones', () => {
    describe('when project has license to add group milestones', () => {
      it(`dispatchs fetchProjectMilestones and fetchGroupMilestones`, () => {
        const getters = {
          groupMilestonesEnabled: () => true,
        };

        return testAction(
          actions.fetchMilestones,
          undefined,
          { ...state, ...getters },
          [],
          [{ type: 'fetchProjectMilestones' }, { type: 'fetchGroupMilestones' }],
        );
      });
    });

    describe('when project does not have license to add group milestones', () => {
      it(`dispatchs fetchProjectMilestones`, () => {
        return testAction(
          actions.fetchMilestones,
          undefined,
          state,
          [],
          [{ type: 'fetchProjectMilestones' }],
        );
      });
    });
  });

  describe('fetchProjectMilestones', () => {
    describe('when the fetch is successful', () => {
      const projectMilestonesApiResponse = { data: [{ title: 'v1.0' }] };

      beforeEach(() => {
        mockProjectMilestonesReturnValue = Promise.resolve(projectMilestonesApiResponse);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_PROJECT_MILESTONES_SUCCESS} with the response from the API, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.fetchProjectMilestones, undefined, state, [
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
        return testAction(actions.fetchProjectMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_PROJECT_MILESTONES_ERROR, payload: error },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });
  });

  describe('fetchGroupMilestones', () => {
    describe('when the fetch is successful', () => {
      const groupMilestonesApiResponse = { data: [{ title: 'group-v1.0' }] };

      beforeEach(() => {
        mockGroupMilestonesReturnValue = Promise.resolve(groupMilestonesApiResponse);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_GROUP_MILESTONES_SUCCESS} with the response from the API, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.fetchGroupMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_GROUP_MILESTONES_SUCCESS, payload: groupMilestonesApiResponse },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });

    describe('when the fetch fails', () => {
      const error = new Error('Something went wrong!');

      beforeEach(() => {
        mockGroupMilestonesReturnValue = Promise.reject(error);
      });

      it(`commits ${types.REQUEST_START}, ${types.RECEIVE_GROUP_MILESTONES_ERROR} with the error object, and ${types.REQUEST_FINISH}`, () => {
        return testAction(actions.fetchGroupMilestones, undefined, state, [
          { type: types.REQUEST_START },
          { type: types.RECEIVE_GROUP_MILESTONES_ERROR, payload: error },
          { type: types.REQUEST_FINISH },
        ]);
      });
    });
  });
});
