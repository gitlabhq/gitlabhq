import { DATE_RANGE_OPTIONS, DEFAULT_SELECTED_DATE_RANGE_OPTION } from './constants';

export const getDateRangeOption = (optionKey) => DATE_RANGE_OPTIONS[optionKey] || null;

export const dateRangeOptionToFilter = ({ startDate, endDate, key }) => ({
  startDate,
  endDate,
  dateRangeOption: key,
});

export const getDateRange = (dateRange, defaultOption = DEFAULT_SELECTED_DATE_RANGE_OPTION) => {
  return DATE_RANGE_OPTIONS[dateRange] || DATE_RANGE_OPTIONS[defaultOption];
};
