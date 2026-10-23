import { dayAfter } from '~/lib/utils/datetime_utility';
import { queryThroughputData } from '~/analytics/merge_request_analytics/api';
import {
  filterToMRThroughputQueryObject,
  formatThroughputChartData,
} from '~/analytics/merge_request_analytics/utils';
import {
  DATE_RANGE_OPTIONS,
  DATE_RANGE_OPTION_LAST_365_DAYS,
} from '~/explore/analytics_dashboards/components/constants';

const responseHasAnyData = (rawData) => Object.values(rawData).some(({ count }) => count);

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
  } = DATE_RANGE_OPTIONS[dateRangeOption || dateRange] ||
  DATE_RANGE_OPTIONS[DATE_RANGE_OPTION_LAST_365_DAYS];

  setVisualizationOverrides({ visualizationOptionOverrides: { subtitle } });

  const rawData = await queryThroughputData({
    namespace,
    startDate: filtersStartDate ?? startDate,
    endDate: filtersEndDate ?? dayAfter(endDate, { utc: true }),
    ...filterToMRThroughputQueryObject(searchFilters),
    ...overridesRest,
  });

  if (!responseHasAnyData(rawData)) {
    // return an empty object so the correct dashboard "empty state" is rendered
    return {};
  }

  return formatThroughputChartData(rawData);
}
