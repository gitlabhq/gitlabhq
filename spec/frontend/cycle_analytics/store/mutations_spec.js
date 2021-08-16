import { useFakeDate } from 'helpers/fake_date';
import { DEFAULT_DAYS_TO_DISPLAY } from '~/cycle_analytics/constants';
import * as types from '~/cycle_analytics/store/mutation_types';
import mutations from '~/cycle_analytics/store/mutations';
import {
  selectedStage,
  rawIssueEvents,
  issueEvents,
  selectedValueStream,
  rawValueStreamStages,
  valueStreamStages,
  rawStageMedians,
  formattedStageMedians,
  rawStageCounts,
  stageCounts,
} from '../mock_data';

let state;
const rawEvents = rawIssueEvents.events;
const convertedEvents = issueEvents.events;
const mockRequestPath = 'fake/request/path';
const mockCreatedAfter = '2020-06-18';
const mockCreatedBefore = '2020-07-18';

describe('Project Value Stream Analytics mutations', () => {
  useFakeDate(2020, 6, 18);

  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                                      | stateKey                 | value
    ${types.REQUEST_VALUE_STREAMS}                | ${'valueStreams'}        | ${[]}
    ${types.RECEIVE_VALUE_STREAMS_ERROR}          | ${'valueStreams'}        | ${[]}
    ${types.REQUEST_VALUE_STREAM_STAGES}          | ${'stages'}              | ${[]}
    ${types.RECEIVE_VALUE_STREAM_STAGES_ERROR}    | ${'stages'}              | ${[]}
    ${types.REQUEST_CYCLE_ANALYTICS_DATA}         | ${'isLoading'}           | ${true}
    ${types.REQUEST_CYCLE_ANALYTICS_DATA}         | ${'hasError'}            | ${false}
    ${types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS} | ${'hasError'}            | ${false}
    ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR}   | ${'isLoading'}           | ${false}
    ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR}   | ${'hasError'}            | ${true}
    ${types.REQUEST_STAGE_DATA}                   | ${'isLoadingStage'}      | ${true}
    ${types.REQUEST_STAGE_DATA}                   | ${'isEmptyStage'}        | ${false}
    ${types.REQUEST_STAGE_DATA}                   | ${'hasError'}            | ${false}
    ${types.REQUEST_STAGE_DATA}                   | ${'selectedStageEvents'} | ${[]}
    ${types.RECEIVE_STAGE_DATA_SUCCESS}           | ${'isLoadingStage'}      | ${false}
    ${types.RECEIVE_STAGE_DATA_SUCCESS}           | ${'selectedStageEvents'} | ${[]}
    ${types.RECEIVE_STAGE_DATA_SUCCESS}           | ${'hasError'}            | ${false}
    ${types.RECEIVE_STAGE_DATA_ERROR}             | ${'isLoadingStage'}      | ${false}
    ${types.RECEIVE_STAGE_DATA_ERROR}             | ${'selectedStageEvents'} | ${[]}
    ${types.RECEIVE_STAGE_DATA_ERROR}             | ${'hasError'}            | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}             | ${'isEmptyStage'}        | ${true}
    ${types.REQUEST_STAGE_MEDIANS}                | ${'medians'}             | ${{}}
    ${types.RECEIVE_STAGE_MEDIANS_ERROR}          | ${'medians'}             | ${{}}
    ${types.REQUEST_STAGE_COUNTS}                 | ${'stageCounts'}         | ${{}}
    ${types.RECEIVE_STAGE_COUNTS_ERROR}           | ${'stageCounts'}         | ${{}}
  `('$mutation will set $stateKey to $value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state).toMatchObject({ [stateKey]: value });
  });

  const mockInitialPayload = {
    endpoints: { requestPath: mockRequestPath },
    currentGroup: { title: 'cool-group' },
    id: 1337,
  };
  const mockInitializedObj = {
    endpoints: { requestPath: mockRequestPath },
    createdAfter: mockCreatedAfter,
    createdBefore: mockCreatedBefore,
  };

  it.each`
    mutation                | stateKey           | value
    ${types.INITIALIZE_VSA} | ${'endpoints'}     | ${{ requestPath: mockRequestPath }}
    ${types.INITIALIZE_VSA} | ${'createdAfter'}  | ${mockCreatedAfter}
    ${types.INITIALIZE_VSA} | ${'createdBefore'} | ${mockCreatedBefore}
  `('$mutation will set $stateKey', ({ mutation, stateKey, value }) => {
    mutations[mutation](state, { ...mockInitialPayload });

    expect(state).toMatchObject({ ...mockInitializedObj, [stateKey]: value });
  });

  it.each`
    mutation                                     | payload                             | stateKey                 | value
    ${types.SET_DATE_RANGE}                      | ${DEFAULT_DAYS_TO_DISPLAY}          | ${'daysInPast'}          | ${DEFAULT_DAYS_TO_DISPLAY}
    ${types.SET_DATE_RANGE}                      | ${DEFAULT_DAYS_TO_DISPLAY}          | ${'createdAfter'}        | ${mockCreatedAfter}
    ${types.SET_DATE_RANGE}                      | ${DEFAULT_DAYS_TO_DISPLAY}          | ${'createdBefore'}       | ${mockCreatedBefore}
    ${types.SET_LOADING}                         | ${true}                             | ${'isLoading'}           | ${true}
    ${types.SET_LOADING}                         | ${false}                            | ${'isLoading'}           | ${false}
    ${types.SET_SELECTED_VALUE_STREAM}           | ${selectedValueStream}              | ${'selectedValueStream'} | ${selectedValueStream}
    ${types.RECEIVE_VALUE_STREAMS_SUCCESS}       | ${[selectedValueStream]}            | ${'valueStreams'}        | ${[selectedValueStream]}
    ${types.RECEIVE_VALUE_STREAM_STAGES_SUCCESS} | ${{ stages: rawValueStreamStages }} | ${'stages'}              | ${valueStreamStages}
    ${types.RECEIVE_STAGE_MEDIANS_SUCCESS}       | ${rawStageMedians}                  | ${'medians'}             | ${formattedStageMedians}
    ${types.RECEIVE_STAGE_COUNTS_SUCCESS}        | ${rawStageCounts}                   | ${'stageCounts'}         | ${stageCounts}
  `(
    '$mutation with $payload will set $stateKey to $value',
    ({ mutation, payload, stateKey, value }) => {
      mutations[mutation](state, payload);

      expect(state).toMatchObject({ [stateKey]: value });
    },
  );

  describe('with a stage selected', () => {
    beforeEach(() => {
      state = {
        selectedStage,
      };
    });

    it.each`
      mutation                            | payload      | stateKey                 | value
      ${types.RECEIVE_STAGE_DATA_SUCCESS} | ${[]}        | ${'isEmptyStage'}        | ${true}
      ${types.RECEIVE_STAGE_DATA_SUCCESS} | ${rawEvents} | ${'selectedStageEvents'} | ${convertedEvents}
      ${types.RECEIVE_STAGE_DATA_SUCCESS} | ${rawEvents} | ${'isEmptyStage'}        | ${false}
    `(
      '$mutation with $payload will set $stateKey to $value',
      ({ mutation, payload, stateKey, value }) => {
        mutations[mutation](state, payload);

        expect(state).toMatchObject({ [stateKey]: value });
      },
    );
  });
});
