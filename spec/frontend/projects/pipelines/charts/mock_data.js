export const counts = {
  failed: 2,
  success: 2,
  total: 4,
  successRatio: 50,
  totalDuration: 116158,
};

export const timesChartData = {
  labels: ['as1234', 'kh423hy', 'ji56bvg', 'th23po'],
  values: [5, 3, 7, 4],
};

export const areaChartData = {
  labels: ['01 Jan', '02 Jan', '03 Jan', '04 Jan', '05 Jan'],
  totals: [4, 6, 3, 6, 7],
  success: [3, 5, 3, 3, 5],
};

export const lastYearChartData = {
  ...areaChartData,
  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
};

export const transformedAreaChartData = [
  {
    name: 'all',
    data: [['01 Jan', 4], ['02 Jan', 6], ['03 Jan', 3], ['04 Jan', 6], ['05 Jan', 7]],
  },
  {
    name: 'success',
    data: [['01 Jan', 3], ['02 Jan', 3], ['03 Jan', 3], ['04 Jan', 3], ['05 Jan', 5]],
  },
];
