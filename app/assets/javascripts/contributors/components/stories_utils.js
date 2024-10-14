/* eslint-disable @gitlab/require-i18n-strings */
import { getDatesInRange, toISODateFormat } from '~/lib/utils/datetime_utility';
import Contributors from './contributors.vue';

export const getMasterChartOptions = () => ({
  ...Contributors.methods.getCommonChartOptions(true),
  yAxis: {
    name: 'Number of commits',
  },
  grid: {
    bottom: 64,
    left: 64,
    right: 20,
    top: 20,
  },
});

export const getMasterChartData = (parsedData) => {
  const dates = Object.keys(parsedData.total).sort((a, b) => new Date(a) - new Date(b));

  const firstContributionDate = new Date(dates[0]);
  const lastContributionDate = new Date(dates[dates.length - 1]);

  const xAxisRange = getDatesInRange(firstContributionDate, lastContributionDate, toISODateFormat);

  const data = {};
  xAxisRange.forEach((date) => {
    data[date] = parsedData.total[date] || 0;
  });
  return [
    {
      name: 'Commits',
      data: Object.entries(data),
    },
  ];
};

export const generateRawData = (count, contributors = 3) => {
  const data = [];

  const dates = [];
  for (let i = 0; i < Math.ceil(count / 2); i += 1) {
    const dateToAdd = new Date();
    dateToAdd.setDate(dateToAdd.getDate() - i);
    dates.push(toISODateFormat(dateToAdd));
  }

  for (let i = 0; i < count; i += 1) {
    const contributor = Math.floor(i % contributors);
    data.push({
      author_name: `Author ${contributor}`,
      author_email: `author_${contributor}@example.com`,
      date: dates[Math.floor(Math.random() * (count / 2))],
    });
  }
  return data;
};
