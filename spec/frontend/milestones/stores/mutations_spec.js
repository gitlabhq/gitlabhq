import createState from '~/milestones/stores/state';
import mutations from '~/milestones/stores/mutations';
import * as types from '~/milestones/stores/mutation_types';

describe('Milestones combobox Vuex store mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('initial state', () => {
    it('is created with the correct structure and initial values', () => {
      expect(state).toEqual({
        projectId: null,
        groupId: null,
        query: '',
        matches: {
          projectMilestones: {
            list: [],
            totalCount: 0,
            error: null,
          },
        },
        selectedMilestones: [],
        requestCount: 0,
      });
    });
  });

  describe(`${types.SET_PROJECT_ID}`, () => {
    it('updates the project ID', () => {
      const newProjectId = '4';
      mutations[types.SET_PROJECT_ID](state, newProjectId);

      expect(state.projectId).toBe(newProjectId);
    });
  });

  describe(`${types.SET_SELECTED_MILESTONES}`, () => {
    it('sets the selected milestones', () => {
      const selectedMilestones = ['v1.2.3'];
      mutations[types.SET_SELECTED_MILESTONES](state, selectedMilestones);

      expect(state.selectedMilestones).toEqual(['v1.2.3']);
    });
  });

  describe(`${types.ADD_SELECTED_MILESTONESs}`, () => {
    it('adds the selected milestones', () => {
      const selectedMilestone = 'v1.2.3';
      mutations[types.ADD_SELECTED_MILESTONE](state, selectedMilestone);

      expect(state.selectedMilestones).toEqual(['v1.2.3']);
    });
  });

  describe(`${types.REMOVE_SELECTED_MILESTONES}`, () => {
    it('removes the selected milestones', () => {
      const selectedMilestone = 'v1.2.3';

      mutations[types.SET_SELECTED_MILESTONES](state, [selectedMilestone]);
      expect(state.selectedMilestones).toEqual(['v1.2.3']);

      mutations[types.REMOVE_SELECTED_MILESTONE](state, selectedMilestone);
      expect(state.selectedMilestones).toEqual([]);
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

  describe(`${types.RECEIVE_PROJECT_MILESTONES_SUCCESS}`, () => {
    it('updates state.matches.projectMilestones based on the provided API response', () => {
      const response = {
        data: [
          {
            title: 'v0.1',
          },
          {
            title: 'v0.2',
          },
        ],
        headers: {
          'x-total': 2,
        },
      };

      mutations[types.RECEIVE_PROJECT_MILESTONES_SUCCESS](state, response);

      expect(state.matches.projectMilestones).toEqual({
        list: [
          {
            title: 'v0.1',
          },
          {
            title: 'v0.2',
          },
        ],
        error: null,
        totalCount: 2,
      });
    });

    describe(`${types.RECEIVE_PROJECT_MILESTONES_ERROR}`, () => {
      it('updates state.matches.projectMilestones to an empty state with the error object', () => {
        const error = new Error('Something went wrong!');

        state.matches.projectMilestones = {
          list: [{ title: 'v0.1' }],
          totalCount: 1,
          error: null,
        };

        mutations[types.RECEIVE_PROJECT_MILESTONES_ERROR](state, error);

        expect(state.matches.projectMilestones).toEqual({
          list: [],
          totalCount: 0,
          error,
        });
      });
    });
  });
});
