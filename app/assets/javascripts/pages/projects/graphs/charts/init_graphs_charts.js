import { GlColumnChart } from '@gitlab/ui/src/charts';
import Vue from 'vue';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import CodeCoverage from '../components/code_coverage.vue';
import SeriesDataMixin from './series_data_mixin';

const LANGUAGE_CHART_HEIGHT = 300;
const GRAPHS_PATH_REGEX = /^(.*?)\/-\/graphs/g;

const seriesDataToBarData = (raw) => Object.entries(raw).map(([name, data]) => ({ name, data }));

const reorderWeekDays = (weekDays, firstDayOfWeek = 0) => {
  if (firstDayOfWeek === 0) {
    return weekDays;
  }

  // eslint-disable-next-line max-params
  return Object.keys(weekDays).reduce((acc, dayName, idx, arr) => {
    const reorderedDayName = arr[(idx + firstDayOfWeek) % arr.length];

    return {
      ...acc,
      [reorderedDayName]: weekDays[reorderedDayName],
    };
  }, {});
};

export function initLanguagesChart() {
  const el = document.getElementById('js-languages-chart');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    components: {
      GlColumnChart,
    },
    data() {
      return {
        chartData: JSON.parse(el.dataset.chartData),
      };
    },
    computed: {
      seriesData() {
        return [{ name: 'full', data: this.chartData.map((d) => [d.label, d.value]) }];
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
          responsive: true,
        },
      });
    },
  });
}

export function initCodeCoverageChart() {
  const el = document.getElementById('js-code-coverage-chart');

  if (!el) {
    return null;
  }

  const { graphEndpoint, graphEndDate, graphStartDate, graphRef, graphCsvPath } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(CodeCoverage, {
        props: {
          graphEndpoint,
          graphEndDate,
          graphStartDate,
          graphRef,
          graphCsvPath,
        },
      });
    },
  });
}

export function initMonthChart() {
  const el = document.getElementById('js-month-chart');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    components: {
      GlColumnChart,
    },
    mixins: [SeriesDataMixin],
    data() {
      return {
        chartData: JSON.parse(el.dataset.chartData),
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
        attrs: {
          responsive: true,
        },
      });
    },
  });
}

export function initWeekdayChart() {
  const el = document.getElementById('js-weekday-chart');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    data() {
      return {
        chartData: JSON.parse(el.dataset.chartData),
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
        attrs: {
          responsive: true,
        },
      });
    },
  });
}

export function initHourChart() {
  const el = document.getElementById('js-hour-chart');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    mixins: [SeriesDataMixin],
    data() {
      return {
        chartData: JSON.parse(el.dataset.chartData),
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
        attrs: {
          responsive: true,
        },
      });
    },
  });
}

export function initRefSwitcher() {
  const el = document.getElementById('js-project-graph-ref-switcher');

  if (!el) {
    return null;
  }

  const { projectId, projectBranch, graphPath } = el.dataset;

  const graphsPathPrefix = graphPath.match(GRAPHS_PATH_REGEX)?.[0];
  if (!graphsPathPrefix) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('Path is not correct');
  }

  return new Vue({
    el,
    name: 'RefSelectorRoot',
    render(createComponent) {
      return createComponent(RefSelector, {
        props: {
          enabledRefTypes: [REF_TYPE_BRANCHES, REF_TYPE_TAGS],
          value: projectBranch,
          translations: {
            dropdownHeader: __('Switch branch/tag'),
            searchPlaceholder: __('Search branches and tags'),
          },
          projectId,
        },
        class: 'gl-w-20',
        on: {
          input(selected) {
            visitUrl(`${graphsPathPrefix}/${encodeURIComponent(selected)}/charts`);
          },
        },
      });
    },
  });
}
