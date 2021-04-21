import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/cycle_analytics/store/actions';
import httpStatusCodes from '~/lib/utils/http_status';
import { selectedStage } from '../mock_data';

const mockRequestPath = 'some/cool/path';
const mockStartDate = 30;

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

  it.each`
    action                | type                    | payload                             | expectedActions
    ${'initializeVsa'}    | ${'INITIALIZE_VSA'}     | ${{ requestPath: mockRequestPath }} | ${['fetchCycleAnalyticsData']}
    ${'setDateRange'}     | ${'SET_DATE_RANGE'}     | ${{ startDate: 30 }}                | ${[]}
    ${'setSelectedStage'} | ${'SET_SELECTED_STAGE'} | ${{ selectedStage }}                | ${[]}
  `(
    '$action should dispatch $expectedActions and commit $type',
    ({ action, type, payload, expectedActions }) =>
      testAction({
        action: actions[action],
        state,
        payload,
        expectedMutations: [
          {
            type,
            payload,
          },
        ],
        expectedActions: expectedActions.map((a) => ({ type: a })),
      }),
  );

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
        expectedActions: [{ type: 'setSelectedStage' }, { type: 'fetchStageData' }],
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
    const mockStagePath = `${mockRequestPath}/events/${selectedStage.name}.json`;

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
});
