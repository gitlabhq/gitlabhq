import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/cycle_analytics/store/actions';
import httpStatusCodes from '~/lib/utils/http_status';
import { allowedStages, selectedStage, selectedValueStream } from '../mock_data';

const mockRequestPath = 'some/cool/path';
const mockFullPath = '/namespace/-/analytics/value_stream_analytics/value_streams';
const mockStartDate = 30;
const mockRequestedDataActions = ['fetchValueStreams', 'fetchCycleAnalyticsData'];
const mockInitializeActionCommit = {
  payload: { requestPath: mockRequestPath },
  type: 'INITIALIZE_VSA',
};
const mockSetDateActionCommit = { payload: { startDate: mockStartDate }, type: 'SET_DATE_RANGE' };
const mockRequestedDataMutations = [
  {
    payload: true,
    type: 'SET_LOADING',
  },
  {
    payload: false,
    type: 'SET_LOADING',
  },
];

const features = {
  cycleAnalyticsForGroups: true,
};

describe('Project Value Stream Analytics actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = {};
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = {};
  });

  const mutationTypes = (arr) => arr.map(({ type }) => type);

  describe.each`
    action                      | payload                             | expectedActions               | expectedMutations
    ${'initializeVsa'}          | ${{ requestPath: mockRequestPath }} | ${mockRequestedDataActions}   | ${[mockInitializeActionCommit, ...mockRequestedDataMutations]}
    ${'setDateRange'}           | ${{ startDate: mockStartDate }}     | ${mockRequestedDataActions}   | ${[mockSetDateActionCommit, ...mockRequestedDataMutations]}
    ${'setSelectedStage'}       | ${{ selectedStage }}                | ${['fetchStageData']}         | ${[{ type: 'SET_SELECTED_STAGE', payload: { selectedStage } }]}
    ${'setSelectedValueStream'} | ${{ selectedValueStream }}          | ${['fetchValueStreamStages']} | ${[{ type: 'SET_SELECTED_VALUE_STREAM', payload: { selectedValueStream } }]}
  `('$action', ({ action, payload, expectedActions, expectedMutations }) => {
    const types = mutationTypes(expectedMutations);

    it(`will dispatch ${expectedActions} and commit ${types}`, () =>
      testAction({
        action: actions[action],
        state,
        payload,
        expectedMutations,
        expectedActions: expectedActions.map((a) => ({ type: a })),
      }));
  });

  describe('fetchCycleAnalyticsData', () => {
    beforeEach(() => {
      state = { requestPath: mockRequestPath };
      mock = new MockAdapter(axios);
      mock.onGet(mockRequestPath).reply(httpStatusCodes.OK);
    });

    it(`dispatches the 'setSelectedStage' and 'fetchStageData' actions`, () =>
      testAction({
        action: actions.fetchCycleAnalyticsData,
        state,
        payload: {},
        expectedMutations: [
          { type: 'REQUEST_CYCLE_ANALYTICS_DATA' },
          { type: 'RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS' },
        ],
        expectedActions: [],
      }));

    describe('with a failing request', () => {
      beforeEach(() => {
        state = { requestPath: mockRequestPath };
        mock = new MockAdapter(axios);
        mock.onGet(mockRequestPath).reply(httpStatusCodes.BAD_REQUEST);
      });

      it(`commits the 'RECEIVE_CYCLE_ANALYTICS_DATA_ERROR' mutation`, () =>
        testAction({
          action: actions.fetchCycleAnalyticsData,
          state,
          payload: {},
          expectedMutations: [
            { type: 'REQUEST_CYCLE_ANALYTICS_DATA' },
            { type: 'RECEIVE_CYCLE_ANALYTICS_DATA_ERROR' },
          ],
          expectedActions: [],
        }));
    });
  });

  describe('fetchStageData', () => {
    const mockStagePath = `${mockRequestPath}/events/${selectedStage.name}`;

    beforeEach(() => {
      state = {
        requestPath: mockRequestPath,
        startDate: mockStartDate,
        selectedStage,
      };
      mock = new MockAdapter(axios);
      mock.onGet(mockStagePath).reply(httpStatusCodes.OK);
    });

    it(`commits the 'RECEIVE_STAGE_DATA_SUCCESS' mutation`, () =>
      testAction({
        action: actions.fetchStageData,
        state,
        payload: {},
        expectedMutations: [{ type: 'REQUEST_STAGE_DATA' }, { type: 'RECEIVE_STAGE_DATA_SUCCESS' }],
        expectedActions: [],
      }));

    describe('with a successful request, but an error in the payload', () => {
      const tooMuchDataError = 'Too much data';

      beforeEach(() => {
        state = {
          requestPath: mockRequestPath,
          startDate: mockStartDate,
          selectedStage,
        };
        mock = new MockAdapter(axios);
        mock.onGet(mockStagePath).reply(httpStatusCodes.OK, { error: tooMuchDataError });
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
          requestPath: mockRequestPath,
          startDate: mockStartDate,
          selectedStage,
        };
        mock = new MockAdapter(axios);
        mock.onGet(mockStagePath).reply(httpStatusCodes.BAD_REQUEST);
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
      state = {
        features,
        fullPath: mockFullPath,
      };
      mock = new MockAdapter(axios);
      mock.onGet(mockValueStreamPath).reply(httpStatusCodes.OK);
    });

    it(`commits the 'REQUEST_VALUE_STREAMS' mutation`, () =>
      testAction({
        action: actions.fetchValueStreams,
        state,
        payload: {},
        expectedMutations: [{ type: 'REQUEST_VALUE_STREAMS' }],
        expectedActions: [
          { type: 'receiveValueStreamsSuccess' },
          { type: 'setSelectedStage' },
          { type: 'fetchStageMedians' },
        ],
      }));

    describe('with cycleAnalyticsForGroups=false', () => {
      beforeEach(() => {
        state = {
          features: { cycleAnalyticsForGroups: false },
          fullPath: mockFullPath,
        };
        mock = new MockAdapter(axios);
        mock.onGet(mockValueStreamPath).reply(httpStatusCodes.OK);
      });

      it("does not dispatch the 'fetchStageMedians' request", () =>
        testAction({
          action: actions.fetchValueStreams,
          state,
          payload: {},
          expectedMutations: [{ type: 'REQUEST_VALUE_STREAMS' }],
          expectedActions: [{ type: 'receiveValueStreamsSuccess' }, { type: 'setSelectedStage' }],
        }));
    });

    describe('with a failing request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet(mockValueStreamPath).reply(httpStatusCodes.BAD_REQUEST);
      });

      it(`commits the 'RECEIVE_VALUE_STREAMS_ERROR' mutation`, () =>
        testAction({
          action: actions.fetchValueStreams,
          state,
          payload: {},
          expectedMutations: [
            { type: 'REQUEST_VALUE_STREAMS' },
            { type: 'RECEIVE_VALUE_STREAMS_ERROR', payload: httpStatusCodes.BAD_REQUEST },
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
    it('with data, will set the first value stream', () => {
      testAction({
        action: actions.receiveValueStreamsSuccess,
        state,
        payload: mockValueStreams,
        expectedMutations: [{ type: 'RECEIVE_VALUE_STREAMS_SUCCESS', payload: mockValueStreams }],
        expectedActions: [{ type: 'setSelectedValueStream', payload: mockValueStream }],
      });
    });

    it('without data, will set the default value stream', () => {
      testAction({
        action: actions.receiveValueStreamsSuccess,
        state,
        payload: [],
        expectedMutations: [{ type: 'RECEIVE_VALUE_STREAMS_SUCCESS', payload: [] }],
        expectedActions: [{ type: 'setSelectedValueStream', payload: selectedValueStream }],
      });
    });
  });

  describe('fetchValueStreamStages', () => {
    const mockValueStreamPath = /\/analytics\/value_stream_analytics\/value_streams/;

    beforeEach(() => {
      state = {
        fullPath: mockFullPath,
        selectedValueStream,
      };
      mock = new MockAdapter(axios);
      mock.onGet(mockValueStreamPath).reply(httpStatusCodes.OK);
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
        mock.onGet(mockValueStreamPath).reply(httpStatusCodes.BAD_REQUEST);
      });

      it(`commits the 'RECEIVE_VALUE_STREAM_STAGES_ERROR' mutation`, () =>
        testAction({
          action: actions.fetchValueStreamStages,
          state,
          payload: {},
          expectedMutations: [
            { type: 'REQUEST_VALUE_STREAM_STAGES' },
            { type: 'RECEIVE_VALUE_STREAM_STAGES_ERROR', payload: httpStatusCodes.BAD_REQUEST },
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
      `Request failed with status code ${httpStatusCodes.BAD_REQUEST}`,
    );

    beforeEach(() => {
      state = {
        fullPath: mockFullPath,
        selectedValueStream,
        stages: allowedStages,
      };
      mock = new MockAdapter(axios);
      mock.onGet(mockValueStreamPath).reply(httpStatusCodes.OK);
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
        mock.onGet(mockValueStreamPath).reply(httpStatusCodes.BAD_REQUEST);
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
});
