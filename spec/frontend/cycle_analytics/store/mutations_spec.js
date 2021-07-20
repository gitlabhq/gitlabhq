import { useFakeDate } from 'helpers/fake_date';
import { DEFAULT_DAYS_TO_DISPLAY } from '~/cycle_analytics/constants';
import * as types from '~/cycle_analytics/store/mutation_types';
import mutations from '~/cycle_analytics/store/mutations';
import {
  selectedStage,
  rawEvents,
  convertedEvents,
  rawData,
  convertedData,
  selectedValueStream,
  rawValueStreamStages,
  valueStreamStages,
  rawStageMedians,
  formattedStageMedians,
} from '../mock_data';

let state;
const mockRequestPath = 'fake/request/path';
const mockCreatedAfter = '2020-06-18';
const mockCreatedBefore = '2020-07-18';
const features = {
  cycleAnalyticsForGroups: true,
};

describe('Project Value Stream Analytics mutations', () => {
  useFakeDate(2020, 6, 18);

  beforeEach(() => {
    state = { features };
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
  `('$mutation will set $stateKey to $value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state, {});

    expect(state).toMatchObject({ [stateKey]: value });
  });

  it.each`
    mutation                                      | payload                                   | stateKey                 | value
    ${types.INITIALIZE_VSA}                       | ${{ requestPath: mockRequestPath }}       | ${'requestPath'}         | ${mockRequestPath}
    ${types.SET_DATE_RANGE}                       | ${{ startDate: DEFAULT_DAYS_TO_DISPLAY }} | ${'startDate'}           | ${DEFAULT_DAYS_TO_DISPLAY}
    ${types.SET_DATE_RANGE}                       | ${{ startDate: DEFAULT_DAYS_TO_DISPLAY }} | ${'createdAfter'}        | ${mockCreatedAfter}
    ${types.SET_DATE_RANGE}                       | ${{ startDate: DEFAULT_DAYS_TO_DISPLAY }} | ${'createdBefore'}       | ${mockCreatedBefore}
    ${types.SET_LOADING}                          | ${true}                                   | ${'isLoading'}           | ${true}
    ${types.SET_LOADING}                          | ${false}                                  | ${'isLoading'}           | ${false}
    ${types.SET_SELECTED_VALUE_STREAM}            | ${selectedValueStream}                    | ${'selectedValueStream'} | ${selectedValueStream}
    ${types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS} | ${rawData}                                | ${'summary'}             | ${convertedData.summary}
    ${types.RECEIVE_VALUE_STREAMS_SUCCESS}        | ${[selectedValueStream]}                  | ${'valueStreams'}        | ${[selectedValueStream]}
    ${types.RECEIVE_VALUE_STREAM_STAGES_SUCCESS}  | ${{ stages: rawValueStreamStages }}       | ${'stages'}              | ${valueStreamStages}
    ${types.RECEIVE_VALUE_STREAMS_SUCCESS}        | ${[selectedValueStream]}                  | ${'valueStreams'}        | ${[selectedValueStream]}
    ${types.RECEIVE_STAGE_MEDIANS_SUCCESS}        | ${rawStageMedians}                        | ${'medians'}             | ${formattedStageMedians}
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
      mutation                            | payload                  | stateKey                 | value
      ${types.RECEIVE_STAGE_DATA_SUCCESS} | ${{ events: [] }}        | ${'isEmptyStage'}        | ${true}
      ${types.RECEIVE_STAGE_DATA_SUCCESS} | ${{ events: rawEvents }} | ${'selectedStageEvents'} | ${convertedEvents}
      ${types.RECEIVE_STAGE_DATA_SUCCESS} | ${{ events: rawEvents }} | ${'isEmptyStage'}        | ${false}
    `(
      '$mutation with $payload will set $stateKey to $value',
      ({ mutation, payload, stateKey, value }) => {
        mutations[mutation](state, payload);

        expect(state).toMatchObject({ [stateKey]: value });
      },
    );
  });

  describe('with cycleAnalyticsForGroups=false', () => {
    useFakeDate(2020, 6, 18);

    beforeEach(() => {
      state = { features: { cycleAnalyticsForGroups: false } };
    });

    const formattedMedians = {
      code: '2d',
      issue: '-',
      plan: '21h',
      review: '-',
      staging: '2d',
      test: '4h',
    };

    it.each`
      mutation                                      | payload    | stateKey     | value
      ${types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS} | ${rawData} | ${'medians'} | ${formattedMedians}
      ${types.REQUEST_CYCLE_ANALYTICS_DATA}         | ${{}}      | ${'medians'} | ${{}}
      ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR}   | ${{}}      | ${'medians'} | ${{}}
    `(
      '$mutation with $payload will set $stateKey to $value',
      ({ mutation, payload, stateKey, value }) => {
        mutations[mutation](state, payload);

        expect(state).toMatchObject({ [stateKey]: value });
      },
    );
  });
});
