import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/analytics/cycle_analytics/store/actions';
import * as getters from '~/analytics/cycle_analytics/store/getters';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  allowedStages,
  selectedStage,
  selectedValueStream,
  currentGroup,
  createdAfter,
  createdBefore,
  initialPaginationState,
  reviewEvents,
  projectNamespace as namespace,
  predefinedDateRange,
} from '../mock_data';

const { path: groupPath } = currentGroup;
const mockMilestonesPath = `/${namespace.restApiRequestPath}/-/milestones.json`;
const mockLabelsPath = `/${namespace.restApiRequestPath}/-/labels.json`;
const mockFullPath = '/namespace/-/analytics/value_stream_analytics/value_streams';
const mockSetDateActionCommit = {
  payload: { createdAfter, createdBefore },
  type: 'SET_DATE_RANGE',
};

const defaultState = {
  ...getters,
  namespace,
  selectedValueStream,
  createdAfter,
  createdBefore,
  pagination: initialPaginationState,
  predefinedDateRange,
};

describe('Project Value Stream Analytics actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = { ...defaultState };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = {};
  });

  const mutationTypes = (arr) => arr.map(({ type }) => type);

  describe.each`
    action                      | payload                            | expectedActions                         | expectedMutations
    ${'setDateRange'}           | ${{ createdAfter, createdBefore }} | ${[{ type: 'refetchStageData' }]}       | ${[mockSetDateActionCommit]}
    ${'setPredefinedDateRange'} | ${{ predefinedDateRange }}         | ${[]}                                   | ${[{ type: 'SET_PREDEFINED_DATE_RANGE', payload: { predefinedDateRange } }]}
    ${'setFilters'}             | ${[]}                              | ${[{ type: 'refetchStageData' }]}       | ${[]}
    ${'setSelectedStage'}       | ${{ selectedStage }}               | ${[{ type: 'refetchStageData' }]}       | ${[{ type: 'SET_SELECTED_STAGE', payload: { selectedStage } }]}
    ${'setSelectedValueStream'} | ${{ selectedValueStream }}         | ${[{ type: 'fetchValueStreamStages' }]} | ${[{ type: 'SET_SELECTED_VALUE_STREAM', payload: { selectedValueStream } }]}
  `('$action', ({ action, payload, expectedActions, expectedMutations }) => {
    const types = mutationTypes(expectedMutations);
    it(`will dispatch ${expectedActions} and commit ${types}`, () =>
      testAction({
        action: actions[action],
        state,
        payload,
        expectedMutations,
        expectedActions,
      }));
  });

  describe('initializeVsa', () => {
    const selectedAuthor = 'Author';
    const selectedMilestone = 'Milestone 1';
    const selectedAssigneeList = ['Assignee 1', 'Assignee 2'];
    const selectedLabelList = ['Label 1', 'Label 2'];
    const payload = {
      namespace,
      groupPath,
      selectedAuthor,
      selectedMilestone,
      selectedAssigneeList,
      selectedLabelList,
      selectedStage,
    };
    const mockFilterEndpoints = {
      groupEndpoint: 'foo',
      labelsEndpoint: mockLabelsPath,
      milestonesEndpoint: mockMilestonesPath,
      projectEndpoint: namespace.restApiRequestPath,
    };

    it('will dispatch fetchValueStreams actions and commit SET_LOADING and INITIALIZE_VSA', () => {
      return testAction({
        action: actions.initializeVsa,
        state: {},
        payload,
        expectedMutations: [
          { type: 'INITIALIZE_VSA', payload },
          { type: 'SET_LOADING', payload: true },
          { type: 'SET_LOADING', payload: false },
        ],
        expectedActions: [
          { type: 'filters/setEndpoints', payload: mockFilterEndpoints },
          {
            type: 'filters/initialize',
            payload: { selectedAuthor, selectedMilestone, selectedAssigneeList, selectedLabelList },
          },
          { type: 'fetchValueStreams' },
          { type: 'setInitialStage', payload: selectedStage },
        ],
      });
    });
  });

  describe('setInitialStage', () => {
    beforeEach(() => {
      state = { ...state, stages: allowedStages };
    });

    describe('with a selected stage', () => {
      it('will commit `SET_SELECTED_STAGE` and fetchValueStreamStageData actions', () => {
        const fakeStage = { ...selectedStage, id: 'fake', name: 'fake-stae' };
        return testAction({
          action: actions.setInitialStage,
          state,
          payload: fakeStage,
          expectedMutations: [
            {
              type: 'SET_SELECTED_STAGE',
              payload: fakeStage,
            },
          ],
          expectedActions: [{ type: 'fetchValueStreamStageData' }],
        });
      });
    });

    describe('without a selected stage', () => {
      it('will select the first stage from the value stream', () => {
        const [firstStage] = allowedStages;
        return testAction({
          action: actions.setInitialStage,
          state,
          payload: null,
          expectedMutations: [{ type: 'SET_SELECTED_STAGE', payload: firstStage }],
          expectedActions: [{ type: 'fetchValueStreamStageData' }],
        });
      });
    });

    describe('with no value stream stages available', () => {
      it('will return SET_NO_ACCESS_ERROR', () => {
        state = { ...state, stages: [] };
        return testAction({
          action: actions.setInitialStage,
          state,
          payload: null,
          expectedMutations: [{ type: 'SET_NO_ACCESS_ERROR' }],
          expectedActions: [],
        });
      });
    });
  });

  describe('updateStageTablePagination', () => {
    beforeEach(() => {
      state = { ...state, selectedStage };
    });

    it(`will dispatch the "fetchStageData" action and commit the 'SET_PAGINATION' mutation`, () => {
      return testAction({
        action: actions.updateStageTablePagination,
        state,
        expectedMutations: [{ type: 'SET_PAGINATION' }],
        expectedActions: [{ type: 'fetchStageData', payload: selectedStage.id }],
      });
    });
  });

  describe('fetchStageData', () => {
    const mockStagePath = /value_streams\/\w+\/stages\/\w+\/records/;
    const headers = {
      'X-Next-Page': 2,
      'X-Page': 1,
    };

    beforeEach(() => {
      state = {
        ...defaultState,
        selectedStage,
      };
      mock = new MockAdapter(axios);
      mock.onGet(mockStagePath).reply(HTTP_STATUS_OK, reviewEvents, headers);
    });

    it(`commits the 'RECEIVE_STAGE_DATA_SUCCESS' mutation`, () =>
      testAction({
        action: actions.fetchStageData,
        state,
        payload: {},
        expectedMutations: [
          { type: 'REQUEST_STAGE_DATA' },
          { type: 'RECEIVE_STAGE_DATA_SUCCESS', payload: reviewEvents },
          { type: 'SET_PAGINATION', payload: { hasNextPage: true, page: 1 } },
        ],
        expectedActions: [],
      }));

    describe('with a successful request, but an error in the payload', () => {
      const tooMuchDataError = 'Too much data';

      beforeEach(() => {
        state = {
          ...defaultState,
          selectedStage,
        };
        mock = new MockAdapter(axios);
        mock.onGet(mockStagePath).reply(HTTP_STATUS_OK, { error: tooMuchDataError });
      });

      it(`commits the 'RECEIVE_STAGE_DATA_ERROR' mutation`, () =>
        testAction({
          action: actions.fetchStageData,
          state,
          payload: { error: tooMuchDataError },
          expectedMutations: [
            { type: 'REQUEST_STAGE_DATA' },
            { type: 'RECEIVE_STAGE_DATA_ERROR', payload: tooMuchDataError },
          ],
          expectedActions: [],
        }));
    });

    describe('with a failing request', () => {
      beforeEach(() => {
        state = {
          ...defaultState,
          selectedStage,
        };
        mock = new MockAdapter(axios);
        mock.onGet(mockStagePath).reply(HTTP_STATUS_BAD_REQUEST);
      });

      it(`commits the 'RECEIVE_STAGE_DATA_ERROR' mutation`, () =>
        testAction({
          action: actions.fetchStageData,
          state,
          payload: {},
          expectedMutations: [{ type: 'REQUEST_STAGE_DATA' }, { type: 'RECEIVE_STAGE_DATA_ERROR' }],
          expectedActions: [],
        }));
    });
  });

  describe('fetchValueStreams', () => {
    const mockValueStreamPath = /\/analytics\/value_stream_analytics\/value_streams/;

    beforeEach(() => {
      state = { namespace };
      mock = new MockAdapter(axios);
      mock.onGet(mockValueStreamPath).reply(HTTP_STATUS_OK);
    });

    it(`commits the 'REQUEST_VALUE_STREAMS' mutation`, () =>
      testAction({
        action: actions.fetchValueStreams,
        state,
        payload: {},
        expectedMutations: [{ type: 'REQUEST_VALUE_STREAMS' }],
        expectedActions: [{ type: 'receiveValueStreamsSuccess' }],
      }));

    describe('with a failing request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet(mockValueStreamPath).reply(HTTP_STATUS_BAD_REQUEST);
      });

      it(`commits the 'RECEIVE_VALUE_STREAMS_ERROR' mutation`, () =>
        testAction({
          action: actions.fetchValueStreams,
          state,
          payload: {},
          expectedMutations: [
            { type: 'REQUEST_VALUE_STREAMS' },
            { type: 'RECEIVE_VALUE_STREAMS_ERROR', payload: HTTP_STATUS_BAD_REQUEST },
          ],
          expectedActions: [],
        }));
    });
  });

  describe('receiveValueStreamsSuccess', () => {
    const mockValueStream = {
      id: 'mockDefault',
      name: 'mock default',
    };
    const mockValueStreams = [mockValueStream, selectedValueStream];
    it('with data, will set the first value stream', () =>
      testAction({
        action: actions.receiveValueStreamsSuccess,
        state,
        payload: mockValueStreams,
        expectedMutations: [{ type: 'RECEIVE_VALUE_STREAMS_SUCCESS', payload: mockValueStreams }],
        expectedActions: [{ type: 'setSelectedValueStream', payload: mockValueStream }],
      }));

    it('without data, will set the default value stream', () =>
      testAction({
        action: actions.receiveValueStreamsSuccess,
        state,
        payload: [],
        expectedMutations: [{ type: 'RECEIVE_VALUE_STREAMS_SUCCESS', payload: [] }],
        expectedActions: [{ type: 'setSelectedValueStream', payload: selectedValueStream }],
      }));
  });

  describe('fetchValueStreamStages', () => {
    const mockValueStreamPath = /\/analytics\/value_stream_analytics\/value_streams/;

    beforeEach(() => {
      state = {
        namespace,
        selectedValueStream,
      };
      mock = new MockAdapter(axios);
      mock.onGet(mockValueStreamPath).reply(HTTP_STATUS_OK);
    });

    it(`commits the 'REQUEST_VALUE_STREAM_STAGES' and 'RECEIVE_VALUE_STREAM_STAGES_SUCCESS' mutations`, () =>
      testAction({
        action: actions.fetchValueStreamStages,
        state,
        payload: {},
        expectedMutations: [
          { type: 'REQUEST_VALUE_STREAM_STAGES' },
          { type: 'RECEIVE_VALUE_STREAM_STAGES_SUCCESS' },
        ],
        expectedActions: [],
      }));

    describe('with a failing request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet(mockValueStreamPath).reply(HTTP_STATUS_BAD_REQUEST);
      });

      it(`commits the 'RECEIVE_VALUE_STREAM_STAGES_ERROR' mutation`, () =>
        testAction({
          action: actions.fetchValueStreamStages,
          state,
          payload: {},
          expectedMutations: [
            { type: 'REQUEST_VALUE_STREAM_STAGES' },
            { type: 'RECEIVE_VALUE_STREAM_STAGES_ERROR', payload: HTTP_STATUS_BAD_REQUEST },
          ],
          expectedActions: [],
        }));
    });
  });

  describe('fetchStageMedians', () => {
    const mockValueStreamPath = /median/;

    const stageMediansPayload = [
      { id: 'issue', value: null },
      { id: 'plan', value: null },
      { id: 'code', value: null },
    ];

    const stageMedianError = new Error(
      `Request failed with status code ${HTTP_STATUS_BAD_REQUEST}`,
    );

    beforeEach(() => {
      state = {
        fullPath: mockFullPath,
        selectedValueStream,
        stages: allowedStages,
      };
      mock = new MockAdapter(axios);
      mock.onGet(mockValueStreamPath).reply(HTTP_STATUS_OK);
    });

    it(`commits the 'REQUEST_STAGE_MEDIANS' and 'RECEIVE_STAGE_MEDIANS_SUCCESS' mutations`, () =>
      testAction({
        action: actions.fetchStageMedians,
        state,
        payload: {},
        expectedMutations: [
          { type: 'REQUEST_STAGE_MEDIANS' },
          { type: 'RECEIVE_STAGE_MEDIANS_SUCCESS', payload: stageMediansPayload },
        ],
        expectedActions: [],
      }));

    describe('with a failing request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet(mockValueStreamPath).reply(HTTP_STATUS_BAD_REQUEST);
      });

      it(`commits the 'RECEIVE_VALUE_STREAM_STAGES_ERROR' mutation`, () =>
        testAction({
          action: actions.fetchStageMedians,
          state,
          payload: {},
          expectedMutations: [
            { type: 'REQUEST_STAGE_MEDIANS' },
            { type: 'RECEIVE_STAGE_MEDIANS_ERROR', payload: stageMedianError },
          ],
          expectedActions: [],
        }));
    });
  });

  describe('fetchStageCountValues', () => {
    const mockValueStreamPath = /count/;
    const stageCountsPayload = [
      { id: 'issue', count: 1 },
      { id: 'plan', count: 2 },
      { id: 'code', count: 3 },
    ];

    const stageCountError = new Error(`Request failed with status code ${HTTP_STATUS_BAD_REQUEST}`);

    beforeEach(() => {
      state = {
        fullPath: mockFullPath,
        selectedValueStream,
        stages: allowedStages,
      };
      mock = new MockAdapter(axios);
      mock
        .onGet(mockValueStreamPath)
        .replyOnce(HTTP_STATUS_OK, { count: 1 })
        .onGet(mockValueStreamPath)
        .replyOnce(HTTP_STATUS_OK, { count: 2 })
        .onGet(mockValueStreamPath)
        .replyOnce(HTTP_STATUS_OK, { count: 3 });
    });

    it(`commits the 'REQUEST_STAGE_COUNTS' and 'RECEIVE_STAGE_COUNTS_SUCCESS' mutations`, () =>
      testAction({
        action: actions.fetchStageCountValues,
        state,
        payload: {},
        expectedMutations: [
          { type: 'REQUEST_STAGE_COUNTS' },
          { type: 'RECEIVE_STAGE_COUNTS_SUCCESS', payload: stageCountsPayload },
        ],
        expectedActions: [],
      }));

    describe('with a failing request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet(mockValueStreamPath).reply(HTTP_STATUS_BAD_REQUEST);
      });

      it(`commits the 'RECEIVE_STAGE_COUNTS_ERROR' mutation`, () =>
        testAction({
          action: actions.fetchStageCountValues,
          state,
          payload: {},
          expectedMutations: [
            { type: 'REQUEST_STAGE_COUNTS' },
            { type: 'RECEIVE_STAGE_COUNTS_ERROR', payload: stageCountError },
          ],
          expectedActions: [],
        }));
    });
  });

  describe('refetchStageData', () => {
    it('will commit SET_LOADING and dispatch fetchValueStreamStageData actions', () =>
      testAction({
        action: actions.refetchStageData,
        state,
        payload: {},
        expectedMutations: [
          { type: 'SET_LOADING', payload: true },
          { type: 'SET_LOADING', payload: false },
        ],
        expectedActions: [{ type: 'fetchValueStreamStageData' }],
      }));
  });

  describe('fetchValueStreamStageData', () => {
    it('will dispatch the fetchStageData, fetchStageMedians and fetchStageCountValues actions', () =>
      testAction({
        action: actions.fetchValueStreamStageData,
        state,
        payload: {},
        expectedMutations: [],
        expectedActions: [
          { type: 'fetchStageData' },
          { type: 'fetchStageMedians' },
          { type: 'fetchStageCountValues' },
        ],
      }));
  });
});
