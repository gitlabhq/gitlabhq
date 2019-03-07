import $ from 'jquery';
import Chart from 'chart.js';
import _ from 'underscore';

import { barChartOptions, pieChartOptions } from '~/lib/utils/chart_utils';

document.addEventListener('DOMContentLoaded', () => {
  const projectChartData = JSON.parse(document.getElementById('projectChartData').innerHTML);

  const barChart = (selector, data) => {
    // get selector by context
    const ctx = selector.get(0).getContext('2d');
    // pointing parent container to make chart.js inherit its width
    const container = $(selector).parent();
    selector.attr('width', $(container).width());

    // Scale fonts if window width lower than 768px (iPad portrait)
    const shouldAdjustFontSize = window.innerWidth < 768;
    return new Chart(ctx, {
      type: 'bar',
      data,
      options: barChartOptions(shouldAdjustFontSize),
    });
  };

  const pieChart = (context, data) => {
    const options = pieChartOptions();

    return new Chart(context, {
      type: 'pie',
      data,
      options,
    });
  };

  const chartData = data => ({
    labels: Object.keys(data),
    datasets: [
      {
        backgroundColor: 'rgba(220,220,220,0.5)',
        borderColor: 'rgba(220,220,220,1)',
        borderWidth: 1,
        data: _.values(data),
      },
    ],
  });

  const reorderWeekDays = (weekDays, firstDayOfWeek = 0) => {
    if (firstDayOfWeek === 0) {
      return weekDays;
    }

    return Object.keys(weekDays).reduce((acc, dayName, idx, arr) => {
      const reorderedDayName = arr[(idx + firstDayOfWeek) % arr.length];

      return {
        ...acc,
        [reorderedDayName]: weekDays[reorderedDayName],
      };
    }, {});
  };

  const hourData = chartData(projectChartData.hour);
  barChart($('#hour-chart'), hourData);

  const weekDays = reorderWeekDays(projectChartData.weekDays, gon.first_day_of_week);
  const dayData = chartData(weekDays);
  barChart($('#weekday-chart'), dayData);

  const monthData = chartData(projectChartData.month);
  barChart($('#month-chart'), monthData);

  const data = {
    datasets: [
      {
        data: projectChartData.languages.map(x => x.value),
        backgroundColor: projectChartData.languages.map(x => x.color),
        hoverBackgroundColor: projectChartData.languages.map(x => x.highlight),
      },
    ],
    labels: projectChartData.languages.map(x => x.label),
  };
  const ctx = $('#languages-chart')
    .get(0)
    .getContext('2d');
  pieChart(ctx, data);
});
