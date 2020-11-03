import { GlColumnChart } from '@gitlab/ui/dist/charts';
import Vue from 'vue';
import { waitForCSSLoaded } from '~/helpers/startup_css_helper';
import { __ } from '~/locale';
import CodeCoverage from '../components/code_coverage.vue';
import SeriesDataMixin from './series_data_mixin';

const seriesDataToBarData = raw => Object.entries(raw).map(([name, data]) => ({ name, data }));

document.addEventListener('DOMContentLoaded', () => {
  waitForCSSLoaded(() => {
    const languagesContainer = document.getElementById('js-languages-chart');
    const codeCoverageContainer = document.getElementById('js-code-coverage-chart');
    const monthContainer = document.getElementById('js-month-chart');
    const weekdayContainer = document.getElementById('js-weekday-chart');
    const hourContainer = document.getElementById('js-hour-chart');
    const LANGUAGE_CHART_HEIGHT = 300;
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

    // eslint-disable-next-line no-new
    new Vue({
      el: languagesContainer,
      components: {
        GlColumnChart,
      },
      data() {
        return {
          chartData: JSON.parse(languagesContainer.dataset.chartData),
        };
      },
      computed: {
        seriesData() {
          return [{ name: 'full', data: this.chartData.map(d => [d.label, d.value]) }];
        },
      },
      render(h) {
        return h(GlColumnChart, {
          props: {
            bars: this.seriesData,
            xAxisTitle: __('Used programming language'),
            yAxisTitle: __('Percentage'),
            xAxisType: 'category',
          },
          attrs: {
            height: LANGUAGE_CHART_HEIGHT,
          },
        });
      },
    });

    // eslint-disable-next-line no-new
    new Vue({
      el: codeCoverageContainer,
      render(h) {
        return h(CodeCoverage, {
          props: {
            graphEndpoint: codeCoverageContainer.dataset?.graphEndpoint,
          },
        });
      },
    });

    // eslint-disable-next-line no-new
    new Vue({
      el: monthContainer,
      components: {
        GlColumnChart,
      },
      mixins: [SeriesDataMixin],
      data() {
        return {
          chartData: JSON.parse(monthContainer.dataset.chartData),
        };
      },
      render(h) {
        return h(GlColumnChart, {
          props: {
            bars: seriesDataToBarData(this.seriesData),
            xAxisTitle: __('Day of month'),
            yAxisTitle: __('No. of commits'),
            xAxisType: 'category',
          },
        });
      },
    });

    // eslint-disable-next-line no-new
    new Vue({
      el: weekdayContainer,
      components: {
        GlColumnChart,
      },
      data() {
        return {
          chartData: JSON.parse(weekdayContainer.dataset.chartData),
        };
      },
      computed: {
        seriesData() {
          const weekDays = reorderWeekDays(this.chartData, gon.first_day_of_week);
          const data = Object.keys(weekDays).reduce((acc, key) => {
            acc.push([key, weekDays[key]]);
            return acc;
          }, []);
          return [{ name: 'full', data }];
        },
      },
      render(h) {
        return h(GlColumnChart, {
          props: {
            bars: this.seriesData,
            xAxisTitle: __('Weekday'),
            yAxisTitle: __('No. of commits'),
            xAxisType: 'category',
          },
        });
      },
    });

    // eslint-disable-next-line no-new
    new Vue({
      el: hourContainer,
      components: {
        GlColumnChart,
      },
      mixins: [SeriesDataMixin],
      data() {
        return {
          chartData: JSON.parse(hourContainer.dataset.chartData),
        };
      },
      render(h) {
        return h(GlColumnChart, {
          props: {
            bars: seriesDataToBarData(this.seriesData),
            xAxisTitle: __('Hour (UTC)'),
            yAxisTitle: __('No. of commits'),
            xAxisType: 'category',
          },
        });
      },
    });
  });
});
