import { useFakeDate } from 'helpers/fake_date';
import * as types from '~/analytics/cycle_analytics/store/mutation_types';
import mutations from '~/analytics/cycle_analytics/store/mutations';
import {
  PAGINATION_SORT_FIELD_DURATION,
  PAGINATION_SORT_DIRECTION_DESC,
} from '~/analytics/cycle_analytics/constants';
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
  initialPaginationState as pagination,
  projectNamespace as mockNamespace,
  predefinedDateRange,
} from '../mock_data';

let state;
const rawEvents = rawIssueEvents.events;
const convertedEvents = issueEvents.events;
const mockGroupPath = 'groups/path';
const mockFeatures = { some: 'feature' };
const mockCreatedAfter = '2020-06-18';
const mockCreatedBefore = '2020-07-18';

describe('Project Value Stream Analytics mutations', () => {
  useFakeDate(2020, 6, 18);

  beforeEach(() => {
    state = { pagination };
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                                   | stateKey                 | value
    ${types.REQUEST_VALUE_STREAMS}             | ${'valueStreams'}        | ${[]}
    ${types.RECEIVE_VALUE_STREAMS_ERROR}       | ${'valueStreams'}        | ${[]}
    ${types.REQUEST_VALUE_STREAM_STAGES}       | ${'stages'}              | ${[]}
    ${types.RECEIVE_VALUE_STREAM_STAGES_ERROR} | ${'stages'}              | ${[]}
    ${types.REQUEST_STAGE_DATA}                | ${'isLoadingStage'}      | ${true}
    ${types.REQUEST_STAGE_DATA}                | ${'isEmptyStage'}        | ${false}
    ${types.REQUEST_STAGE_DATA}                | ${'selectedStageEvents'} | ${[]}
    ${types.RECEIVE_STAGE_DATA_SUCCESS}        | ${'isLoadingStage'}      | ${false}
    ${types.RECEIVE_STAGE_DATA_SUCCESS}        | ${'selectedStageEvents'} | ${[]}
    ${types.RECEIVE_STAGE_DATA_ERROR}          | ${'isLoadingStage'}      | ${false}
    ${types.RECEIVE_STAGE_DATA_ERROR}          | ${'selectedStageEvents'} | ${[]}
    ${types.RECEIVE_STAGE_DATA_ERROR}          | ${'isEmptyStage'}        | ${true}
    ${types.REQUEST_STAGE_MEDIANS}             | ${'medians'}             | ${{}}
    ${types.RECEIVE_STAGE_MEDIANS_ERROR}       | ${'medians'}             | ${{}}
    ${types.REQUEST_STAGE_COUNTS}              | ${'stageCounts'}         | ${{}}
    ${types.RECEIVE_STAGE_COUNTS_ERROR}        | ${'stageCounts'}         | ${{}}
    ${types.SET_NO_ACCESS_ERROR}               | ${'hasNoAccessError'}    | ${true}
  `('$mutation will set $stateKey to $value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state).toMatchObject({ [stateKey]: value });
  });

  const mockSetDatePayload = { createdAfter: mockCreatedAfter, createdBefore: mockCreatedBefore };
  const mockInitialPayload = {
    currentGroup: { title: 'cool-group' },
    id: 1337,
    groupPath: mockGroupPath,
    namespace: mockNamespace,
    features: mockFeatures,
    ...mockSetDatePayload,
  };
  const mockInitializedObj = {
    ...mockSetDatePayload,
  };

  it.each`
    mutation                | stateKey           | value
    ${types.INITIALIZE_VSA} | ${'features'}      | ${mockFeatures}
    ${types.INITIALIZE_VSA} | ${'namespace'}     | ${mockNamespace}
    ${types.INITIALIZE_VSA} | ${'groupPath'}     | ${mockGroupPath}
    ${types.INITIALIZE_VSA} | ${'createdAfter'}  | ${mockCreatedAfter}
    ${types.INITIALIZE_VSA} | ${'createdBefore'} | ${mockCreatedBefore}
  `('$mutation will set $stateKey', ({ mutation, stateKey, value }) => {
    mutations[mutation](state, { ...mockInitialPayload });

    expect(state).toMatchObject({ ...mockInitializedObj, [stateKey]: value });
  });

  it.each`
    mutation                                     | payload                                                  | stateKey                 | value
    ${types.SET_DATE_RANGE}                      | ${mockSetDatePayload}                                    | ${'createdAfter'}        | ${mockCreatedAfter}
    ${types.SET_DATE_RANGE}                      | ${mockSetDatePayload}                                    | ${'createdBefore'}       | ${mockCreatedBefore}
    ${types.SET_PREDEFINED_DATE_RANGE}           | ${predefinedDateRange}                                   | ${'predefinedDateRange'} | ${predefinedDateRange}
    ${types.SET_LOADING}                         | ${true}                                                  | ${'isLoading'}           | ${true}
    ${types.SET_LOADING}                         | ${false}                                                 | ${'isLoading'}           | ${false}
    ${types.SET_SELECTED_VALUE_STREAM}           | ${selectedValueStream}                                   | ${'selectedValueStream'} | ${selectedValueStream}
    ${types.SET_PAGINATION}                      | ${pagination}                                            | ${'pagination'}          | ${{ ...pagination, sort: PAGINATION_SORT_FIELD_DURATION, direction: PAGINATION_SORT_DIRECTION_DESC }}
    ${types.SET_PAGINATION}                      | ${{ ...pagination, sort: 'duration', direction: 'asc' }} | ${'pagination'}          | ${{ ...pagination, sort: 'duration', direction: 'asc' }}
    ${types.SET_SELECTED_STAGE}                  | ${selectedStage}                                         | ${'selectedStage'}       | ${selectedStage}
    ${types.RECEIVE_VALUE_STREAMS_SUCCESS}       | ${[selectedValueStream]}                                 | ${'valueStreams'}        | ${[selectedValueStream]}
    ${types.RECEIVE_VALUE_STREAM_STAGES_SUCCESS} | ${{ stages: rawValueStreamStages }}                      | ${'stages'}              | ${valueStreamStages}
    ${types.RECEIVE_STAGE_MEDIANS_SUCCESS}       | ${rawStageMedians}                                       | ${'medians'}             | ${formattedStageMedians}
    ${types.RECEIVE_STAGE_COUNTS_SUCCESS}        | ${rawStageCounts}                                        | ${'stageCounts'}         | ${stageCounts}
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
