export const mockUsageCounts = [
  { key: 'projects', value: 10, label: 'Projects' },
  { key: 'groups', value: 20, label: 'Group' },
];

export const mockCountsData1 = [
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-07-23', count: 52 },
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-07-22', count: 40 },
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-07-21', count: 31 },
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-06-14', count: 23 },
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-06-12', count: 20 },
];

export const countsMonthlyChartData1 = [
  ['2020-07-01', 41], // average of 2020-07-x items
  ['2020-06-01', 21.5], // average of 2020-06-x items
];

export const mockCountsData2 = [
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-07-28', count: 10 },
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-07-27', count: 9 },
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-06-26', count: 14 },
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-06-25', count: 23 },
  { __typename: 'UsageTrendsMeasurement', recordedAt: '2020-06-24', count: 25 },
];

export const countsMonthlyChartData2 = [
  ['2020-07-01', 9.5], // average of 2020-07-x items
  ['2020-06-01', 20.666666666666668], // average of 2020-06-x items
];

export const roundedSortedCountsMonthlyChartData2 = [
  ['2020-06-01', 21], // average of 2020-06-x items
  ['2020-07-01', 10], // average of 2020-07-x items
];
