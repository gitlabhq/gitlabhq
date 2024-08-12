import { GlColumnChart } from '@gitlab/ui/dist/charts';
import Vue from 'vue';
import { __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import RefSelector from '~/ref/components/ref_selector.vue';
import CodeCoverage from '../components/code_coverage.vue';
import SeriesDataMixin from './series_data_mixin';

const seriesDataToBarData = (raw) => Object.entries(raw).map(([name, data]) => ({ name, data }));

const languagesContainer = document.getElementById('js-languages-chart');
const codeCoverageContainer = document.getElementById('js-code-coverage-chart');
const monthContainer = document.getElementById('js-month-chart');
const weekdayContainer = document.getElementById('js-weekday-chart');
const hourContainer = document.getElementById('js-hour-chart');
const branchSelector = document.getElementById('js-project-graph-ref-switcher');
const LANGUAGE_CHART_HEIGHT = 300;
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

if (codeCoverageContainer?.dataset) {
  const { graphEndpoint, graphEndDate, graphStartDate, graphRef, graphCsvPath } =
    codeCoverageContainer.dataset;
  // eslint-disable-next-line no-new
  new Vue({
    el: codeCoverageContainer,
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
      attrs: {
        responsive: true,
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
      attrs: {
        responsive: true,
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
      attrs: {
        responsive: true,
      },
    });
  },
});

const { projectId, projectBranch, graphPath } = branchSelector.dataset;

const GRAPHS_PATH_REGEX = /^(.*?)\/-\/graphs/g;
const graphsPathPrefix = graphPath.match(GRAPHS_PATH_REGEX)?.[0];
if (!graphsPathPrefix) {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  throw new Error('Path is not correct');
}

// eslint-disable-next-line no-new
new Vue({
  el: branchSelector,
  name: 'RefSelector',
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
