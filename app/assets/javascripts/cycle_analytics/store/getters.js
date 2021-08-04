import dateFormat from 'dateformat';
import { dateFormats } from '~/analytics/shared/constants';
import { transformStagesForPathNavigation, filterStagesByHiddenStatus } from '../utils';

export const pathNavigationData = ({ stages, medians, stageCounts, selectedStage }) => {
  return transformStagesForPathNavigation({
    stages: filterStagesByHiddenStatus(stages, false),
    medians,
    stageCounts,
    selectedStage,
  });
};

export const requestParams = (state) => {
  const {
    endpoints: { fullPath },
    selectedValueStream: { id: valueStreamId },
    selectedStage: { id: stageId = null },
  } = state;
  return { requestPath: fullPath, valueStreamId, stageId };
};

const dateRangeParams = ({ createdAfter, createdBefore }) => ({
  created_after: createdAfter ? dateFormat(createdAfter, dateFormats.isoDate) : null,
  created_before: createdBefore ? dateFormat(createdBefore, dateFormats.isoDate) : null,
});

export const legacyFilterParams = ({ daysInPast }) => {
  return {
    'cycle_analytics[start_date]': daysInPast,
  };
};

export const filterParams = (state) => {
  return {
    ...dateRangeParams(state),
  };
};
