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

// The `custom` option carries no dates of its own, so the filter supplies them. Both bounds
// are taken together or neither is: pairing one supplied bound with a default for the other
// inverts the window when the user has only picked the end of a custom range so far.
export const resolveDateRangeFilter = (
  { startDate, endDate, dateRangeOption } = {},
  defaultOption = DEFAULT_SELECTED_DATE_RANGE_OPTION,
) => {
  const option = getDateRange(dateRangeOption, defaultOption);

  if (startDate && endDate) return { ...option, startDate, endDate };

  return option.startDate && option.endDate ? option : getDateRange(defaultOption);
};
