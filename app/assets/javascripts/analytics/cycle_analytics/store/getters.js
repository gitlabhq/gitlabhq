import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import { filterToQueryObject } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { PAGINATION_TYPE } from '../constants';
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
    namespace: { restApiRequestPath },
    selectedValueStream: { id: valueStreamId },
    selectedStage: { id: stageId = null },
  } = state;
  return { namespacePath: restApiRequestPath, valueStreamId, stageId };
};

export const paginationParams = ({ pagination: { page, sort, direction } }) => ({
  pagination: PAGINATION_TYPE,
  sort,
  direction,
  page,
});

const filterBarParams = ({ filters }) => {
  const {
    authors: { selected: selectedAuthor },
    milestones: { selected: selectedMilestone },
    assignees: { selectedList: selectedAssigneeList },
    labels: { selectedList: selectedLabelList },
  } = filters;
  return filterToQueryObject({
    milestone_title: selectedMilestone,
    author_username: selectedAuthor,
    label_name: selectedLabelList,
    assignee_username: selectedAssigneeList,
  });
};

const dateRangeParams = ({ createdAfter, createdBefore }) => ({
  created_after: createdAfter ? dateFormat(createdAfter, dateFormats.isoDate) : null,
  created_before: createdBefore ? dateFormat(createdBefore, dateFormats.isoDate) : null,
});

export const filterParams = (state) => {
  return {
    ...filterBarParams(state),
    ...dateRangeParams(state),
  };
};
