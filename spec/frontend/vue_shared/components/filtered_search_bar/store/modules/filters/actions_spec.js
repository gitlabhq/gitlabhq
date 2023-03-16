import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { mockBranches } from 'jest/vue_shared/components/filtered_search_bar/mock_data';
import Api from '~/api';
import { createAlert } from '~/alert';
import { HTTP_STATUS_OK, HTTP_STATUS_SERVICE_UNAVAILABLE } from '~/lib/utils/http_status';
import * as actions from '~/vue_shared/components/filtered_search_bar/store/modules/filters/actions';
import * as types from '~/vue_shared/components/filtered_search_bar/store/modules/filters/mutation_types';
import initialState from '~/vue_shared/components/filtered_search_bar/store/modules/filters/state';
import { filterMilestones, filterUsers, filterLabels } from './mock_data';

const milestonesEndpoint = 'fake_milestones_endpoint';
const labelsEndpoint = 'fake_labels_endpoint';
const groupEndpoint = 'fake_group_endpoint';
const projectEndpoint = 'fake_project_endpoint';

jest.mock('~/alert');

describe('Filters actions', () => {
  let state;
  let mock;
  let mockDispatch;
  let mockCommit;

  beforeEach(() => {
    state = initialState();
    mock = new MockAdapter(axios);

    mockDispatch = jest.fn().mockResolvedValue();
    mockCommit = jest.fn();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('initialize', () => {
    const initialData = {
      milestonesEndpoint,
      labelsEndpoint,
      groupEndpoint,
      projectEndpoint,
      selectedAuthor: 'Mr cool',
      selectedMilestone: 'NEXT',
    };

    it('does not dispatch', () => {
      const result = actions.initialize(
        {
          state,
          dispatch: mockDispatch,
          commit: mockCommit,
        },
        initialData,
      );
      expect(result).toBeUndefined();
      expect(mockDispatch).not.toHaveBeenCalled();
    });

    it(`commits the ${types.SET_SELECTED_FILTERS}`, () => {
      actions.initialize(
        {
          state,
          dispatch: mockDispatch,
          commit: mockCommit,
        },
        initialData,
      );
      expect(mockCommit).toHaveBeenCalledWith(types.SET_SELECTED_FILTERS, initialData);
    });
  });

  describe('setFilters', () => {
    const nextFilters = {
      selectedAuthor: 'Mr cool',
      selectedMilestone: 'NEXT',
    };

    it('dispatches the root/setFilters action', () => {
      return testAction(
        actions.setFilters,
        nextFilters,
        state,
        [
          {
            payload: nextFilters,
            type: types.SET_SELECTED_FILTERS,
          },
        ],
        [
          {
            type: 'setFilters',
            payload: nextFilters,
          },
        ],
      );
    });
  });

  describe('setEndpoints', () => {
    it('sets the api paths', () => {
      return testAction(
        actions.setEndpoints,
        { milestonesEndpoint, labelsEndpoint, groupEndpoint, projectEndpoint },
        state,
        [
          { payload: 'fake_milestones_endpoint', type: types.SET_MILESTONES_ENDPOINT },
          { payload: 'fake_labels_endpoint', type: types.SET_LABELS_ENDPOINT },
          { payload: 'fake_group_endpoint', type: types.SET_GROUP_ENDPOINT },
          { payload: 'fake_project_endpoint', type: types.SET_PROJECT_ENDPOINT },
        ],
        [],
      );
    });
  });

  describe('fetchBranches', () => {
    describe('success', () => {
      beforeEach(() => {
        const url = Api.buildUrl(Api.createBranchPath).replace(
          ':id',
          encodeURIComponent(projectEndpoint),
        );
        mock.onGet(url).replyOnce(HTTP_STATUS_OK, mockBranches);
      });

      it('dispatches RECEIVE_BRANCHES_SUCCESS with received data', () => {
        return testAction(
          actions.fetchBranches,
          null,
          { ...state, projectEndpoint },
          [
            { type: types.REQUEST_BRANCHES },
            { type: types.RECEIVE_BRANCHES_SUCCESS, payload: mockBranches },
          ],
          [],
        ).then(({ data }) => {
          expect(data).toBe(mockBranches);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE);
      });

      it('dispatches RECEIVE_BRANCHES_ERROR', () => {
        return testAction(
          actions.fetchBranches,
          null,
          state,
          [
            { type: types.REQUEST_BRANCHES },
            {
              type: types.RECEIVE_BRANCHES_ERROR,
              payload: HTTP_STATUS_SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => expect(createAlert).toHaveBeenCalled());
      });
    });
  });

  describe('fetchAuthors', () => {
    beforeEach(() => {
      gon.api_version = 'v1';
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(HTTP_STATUS_OK, filterUsers);
      });

      it('dispatches RECEIVE_AUTHORS_SUCCESS with received data and groupEndpoint set', () => {
        return testAction(
          actions.fetchAuthors,
          null,
          { ...state, groupEndpoint },
          [
            { type: types.REQUEST_AUTHORS },
            { type: types.RECEIVE_AUTHORS_SUCCESS, payload: filterUsers },
          ],
          [],
        ).then(({ data }) => {
          expect(mock.history.get[0].url).toBe('/api/v1/groups/fake_group_endpoint/members');
          expect(data).toBe(filterUsers);
        });
      });

      it('dispatches RECEIVE_AUTHORS_SUCCESS with received data and projectEndpoint set', () => {
        return testAction(
          actions.fetchAuthors,
          null,
          { ...state, projectEndpoint },
          [
            { type: types.REQUEST_AUTHORS },
            { type: types.RECEIVE_AUTHORS_SUCCESS, payload: filterUsers },
          ],
          [],
        ).then(({ data }) => {
          expect(mock.history.get[0].url).toBe('/api/v1/projects/fake_project_endpoint/users');
          expect(data).toBe(filterUsers);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE);
      });

      it('dispatches RECEIVE_AUTHORS_ERROR and groupEndpoint set', () => {
        return testAction(
          actions.fetchAuthors,
          null,
          { ...state, groupEndpoint },
          [
            { type: types.REQUEST_AUTHORS },
            {
              type: types.RECEIVE_AUTHORS_ERROR,
              payload: HTTP_STATUS_SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => {
          expect(mock.history.get[0].url).toBe('/api/v1/groups/fake_group_endpoint/members');
          expect(createAlert).toHaveBeenCalled();
        });
      });

      it('dispatches RECEIVE_AUTHORS_ERROR and projectEndpoint set', () => {
        return testAction(
          actions.fetchAuthors,
          null,
          { ...state, projectEndpoint },
          [
            { type: types.REQUEST_AUTHORS },
            {
              type: types.RECEIVE_AUTHORS_ERROR,
              payload: HTTP_STATUS_SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => {
          expect(mock.history.get[0].url).toBe('/api/v1/projects/fake_project_endpoint/users');
          expect(createAlert).toHaveBeenCalled();
        });
      });
    });
  });

  describe('fetchMilestones', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(milestonesEndpoint).replyOnce(HTTP_STATUS_OK, filterMilestones);
      });

      it('dispatches RECEIVE_MILESTONES_SUCCESS with received data', () => {
        return testAction(
          actions.fetchMilestones,
          null,
          { ...state, milestonesEndpoint },
          [
            { type: types.REQUEST_MILESTONES },
            { type: types.RECEIVE_MILESTONES_SUCCESS, payload: filterMilestones },
          ],
          [],
        ).then(({ data }) => {
          expect(data).toBe(filterMilestones);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE);
      });

      it('dispatches RECEIVE_MILESTONES_ERROR', () => {
        return testAction(
          actions.fetchMilestones,
          null,
          state,
          [
            { type: types.REQUEST_MILESTONES },
            {
              type: types.RECEIVE_MILESTONES_ERROR,
              payload: HTTP_STATUS_SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => expect(createAlert).toHaveBeenCalled());
      });
    });
  });

  describe('fetchAssignees', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(HTTP_STATUS_OK, filterUsers);
        gon.api_version = 'v1';
      });

      it('dispatches RECEIVE_ASSIGNEES_SUCCESS with received data and groupEndpoint set', () => {
        return testAction(
          actions.fetchAssignees,
          null,
          { ...state, milestonesEndpoint, groupEndpoint },
          [
            { type: types.REQUEST_ASSIGNEES },
            { type: types.RECEIVE_ASSIGNEES_SUCCESS, payload: filterUsers },
          ],
          [],
        ).then(({ data }) => {
          expect(mock.history.get[0].url).toBe('/api/v1/groups/fake_group_endpoint/members');
          expect(data).toBe(filterUsers);
        });
      });

      it('dispatches RECEIVE_ASSIGNEES_SUCCESS with received data and projectEndpoint set', () => {
        return testAction(
          actions.fetchAssignees,
          null,
          { ...state, milestonesEndpoint, projectEndpoint },
          [
            { type: types.REQUEST_ASSIGNEES },
            { type: types.RECEIVE_ASSIGNEES_SUCCESS, payload: filterUsers },
          ],
          [],
        ).then(({ data }) => {
          expect(mock.history.get[0].url).toBe('/api/v1/projects/fake_project_endpoint/users');
          expect(data).toBe(filterUsers);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE);
        gon.api_version = 'v1';
      });

      it('dispatches RECEIVE_ASSIGNEES_ERROR and groupEndpoint set', () => {
        return testAction(
          actions.fetchAssignees,
          null,
          { ...state, groupEndpoint },
          [
            { type: types.REQUEST_ASSIGNEES },
            {
              type: types.RECEIVE_ASSIGNEES_ERROR,
              payload: HTTP_STATUS_SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => {
          expect(mock.history.get[0].url).toBe('/api/v1/groups/fake_group_endpoint/members');
          expect(createAlert).toHaveBeenCalled();
        });
      });

      it('dispatches RECEIVE_ASSIGNEES_ERROR and projectEndpoint set', () => {
        return testAction(
          actions.fetchAssignees,
          null,
          { ...state, projectEndpoint },
          [
            { type: types.REQUEST_ASSIGNEES },
            {
              type: types.RECEIVE_ASSIGNEES_ERROR,
              payload: HTTP_STATUS_SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => {
          expect(mock.history.get[0].url).toBe('/api/v1/projects/fake_project_endpoint/users');
          expect(createAlert).toHaveBeenCalled();
        });
      });
    });
  });

  describe('fetchLabels', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(labelsEndpoint).replyOnce(HTTP_STATUS_OK, filterLabels);
      });

      it('dispatches RECEIVE_LABELS_SUCCESS with received data', () => {
        return testAction(
          actions.fetchLabels,
          null,
          { ...state, labelsEndpoint },
          [
            { type: types.REQUEST_LABELS },
            { type: types.RECEIVE_LABELS_SUCCESS, payload: filterLabels },
          ],
          [],
        ).then(({ data }) => {
          expect(data).toBe(filterLabels);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE);
      });

      it('dispatches RECEIVE_LABELS_ERROR', () => {
        return testAction(
          actions.fetchLabels,
          null,
          state,
          [
            { type: types.REQUEST_LABELS },
            {
              type: types.RECEIVE_LABELS_ERROR,
              payload: HTTP_STATUS_SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => expect(createAlert).toHaveBeenCalled());
      });
    });
  });
});
