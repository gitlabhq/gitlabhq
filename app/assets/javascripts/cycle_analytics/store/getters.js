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
    selectedStage: { id: stageId = null },
    groupPath: groupId,
    selectedValueStream: { id: valueStreamId },
  } = state;
  return { valueStreamId, groupId, stageId };
};

const dateRangeParams = ({ createdAfter, createdBefore }) => ({
  created_after: createdAfter ? dateFormat(createdAfter, dateFormats.isoDate) : null,
  created_before: createdBefore ? dateFormat(createdBefore, dateFormats.isoDate) : null,
});

export const legacyFilterParams = ({ startDate }) => {
  return {
    'cycle_analytics[start_date]': startDate,
  };
};

export const filterParams = ({ id, ...rest }) => {
  return {
    project_ids: [id],
    ...dateRangeParams(rest),
  };
};
