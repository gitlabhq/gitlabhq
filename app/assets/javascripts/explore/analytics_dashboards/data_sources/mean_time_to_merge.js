import { dayAfter } from '~/lib/utils/datetime_utility';
import { queryThroughputData } from '~/analytics/merge_request_analytics/api';
import {
  computeMttmData,
  filterToMRThroughputQueryObject,
} from '~/analytics/merge_request_analytics/utils';
import { getDateRange } from '~/explore/analytics_dashboards/components/utils';
import { DATE_RANGE_OPTION_LAST_365_DAYS } from '~/explore/analytics_dashboards/components/constants';

export default async function fetch({
  namespace,
  query: { dateRange, ...overridesRest } = {},
  filters: {
    startDate: filtersStartDate,
    endDate: filtersEndDate,
    searchFilters,
    dateRangeOption,
  } = {},
  setVisualizationOverrides = () => {},
}) {
  const {
    startDate,
    endDate,
    text: subtitle,
  } = getDateRange(dateRangeOption || dateRange, DATE_RANGE_OPTION_LAST_365_DAYS);

  setVisualizationOverrides({ visualizationOptionOverrides: { subtitle } });

  const rawData = await queryThroughputData({
    namespace,
    startDate: filtersStartDate ?? startDate,
    endDate: filtersEndDate ?? dayAfter(endDate, { utc: true }),
    ...filterToMRThroughputQueryObject(searchFilters),
    ...overridesRest,
  });

  const { value = 0 } = computeMttmData(rawData);
  return value;
}
