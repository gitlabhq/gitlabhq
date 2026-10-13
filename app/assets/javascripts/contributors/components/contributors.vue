<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlFormSelect, GlLoadingIcon } from '@gitlab/ui';
import { debounce } from 'lodash-es';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
import { getDatesInRange, toISODateFormat } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';
import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/vue_shared/components/ref/constants';
import { xAxisLabelFormatter } from '../utils';
import { MASTER_CHART_HEIGHT } from '../constants';
import ContributorAreaChart from './contributor_area_chart.vue';
import IndividualChart from './individual_chart.vue';

const GRAPHS_PATH_REGEX = /^(.*?)\/-\/graphs/g;
const CONTRIBUTION_METRIC_COMMITS = 'commits';
const CONTRIBUTION_METRIC_ADDITIONS = 'additions';
const CONTRIBUTION_METRIC_DELETIONS = 'deletions';
const CONTRIBUTION_METRIC_DATA_KEYS = {
  [CONTRIBUTION_METRIC_COMMITS]: { totalByDate: 'total', authorChartData: 'commitDates' },
  [CONTRIBUTION_METRIC_ADDITIONS]: {
    totalByDate: 'additionsTotal',
    authorChartData: 'additionsDates',
  },
  [CONTRIBUTION_METRIC_DELETIONS]: {
    totalByDate: 'deletionsTotal',
    authorChartData: 'deletionsDates',
  },
};

export default {
  name: 'ContributorsChart',
  MASTER_CHART_HEIGHT,
  i18n: {
    history: __('History'),
    refSelectorTranslations: {
      dropdownHeader: __('Switch branch/tag'),
      searchPlaceholder: __('Search branches and tags'),
    },
  },
  components: {
    GlButton,
    GlFormSelect,
    GlLoadingIcon,
    ContributorAreaChart,
    IndividualChart,
    RefSelector,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    branch: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    commitsPath: {
      type: String,
      required: true,
    },
  },
  refTypes: [REF_TYPE_BRANCHES, REF_TYPE_TAGS],
  data() {
    return {
      masterChart: null,
      individualChartZoom: {},
      selectedBranch: this.branch,
      selectedMetric: CONTRIBUTION_METRIC_COMMITS,
    };
  },
  computed: {
    ...mapState(['loading', 'statsLoading', 'statsLoaded']),
    ...mapGetters(['showChart', 'parsedData']),
    contributionMetricOptions() {
      return [
        { value: CONTRIBUTION_METRIC_COMMITS, text: s__('ContributionAnalytics|Commits') },
        { value: CONTRIBUTION_METRIC_ADDITIONS, text: s__('ContributionAnalytics|Additions') },
        { value: CONTRIBUTION_METRIC_DELETIONS, text: s__('ContributionAnalytics|Deletions') },
      ];
    },
    selectedMetricLabel() {
      return this.contributionMetricOptions.find(({ value }) => value === this.selectedMetric).text;
    },
    selectedMetricYAxisName() {
      if (this.selectedMetric === CONTRIBUTION_METRIC_COMMITS) {
        return s__('ContributionAnalytics|Number of commits');
      }

      if (this.selectedMetric === CONTRIBUTION_METRIC_ADDITIONS) {
        return s__('ContributionAnalytics|Lines added');
      }

      return s__('ContributionAnalytics|Lines deleted');
    },
    selectedMetricYAxis() {
      return {
        name: this.selectedMetricYAxisName,
      };
    },
    selectedMetricDataKeys() {
      return CONTRIBUTION_METRIC_DATA_KEYS[this.selectedMetric];
    },
    selectedMetricTotalByDate() {
      return this.parsedData[this.selectedMetricDataKeys.totalByDate];
    },
    selectedMetricRequiresStats() {
      return this.selectedMetric !== CONTRIBUTION_METRIC_COMMITS;
    },
    selectedMetricStatsLoading() {
      return this.selectedMetricRequiresStats && this.statsLoading;
    },
    masterChartData() {
      return [
        {
          name: this.selectedMetricLabel,
          data: this.datesToChartData(this.selectedMetricTotalByDate),
        },
      ];
    },
    masterChartOptions() {
      return {
        ...this.getCommonChartOptions(true),
        yAxis: this.selectedMetricYAxis,
        grid: {
          bottom: 64,
          left: 64,
          right: 20,
          top: 20,
        },
      };
    },
    individualChartsData() {
      const maxNumberOfIndividualContributorsCharts = 100;

      return Object.keys(this.parsedData.byAuthorEmail)
        .map((email) => {
          const author = this.parsedData.byAuthorEmail[email];
          const commitDates = this.datesToChartData(author.dates);
          const additionsDates = this.datesToChartData(author.additionsByDate);
          const deletionsDates = this.datesToChartData(author.deletionsByDate);
          const chartData = { commitDates, additionsDates, deletionsDates };

          return {
            name: author.name,
            email,
            commits: author.commits,
            additions: author.additions,
            deletions: author.deletions,
            commitDates,
            additionsDates,
            deletionsDates,
            dates: [
              {
                name: this.selectedMetricLabel,
                data: chartData[this.selectedMetricDataKeys.authorChartData],
              },
            ],
          };
        })
        .sort((a, b) => b.commits - a.commits)
        .slice(0, maxNumberOfIndividualContributorsCharts);
    },
    individualChartOptions() {
      return {
        ...this.getCommonChartOptions(false),
        yAxis: {
          ...this.selectedMetricYAxis,
          max: this.individualChartYAxisMax,
        },
        grid: {
          bottom: 27,
          left: 64,
          right: 20,
          top: 8,
        },
      };
    },
    individualChartYAxisMax() {
      return this.individualChartsData.reduce((chartMax, { dates }) => {
        const [{ data }] = dates;
        return data.reduce((dataMax, [, count]) => Math.max(dataMax, count), chartMax);
      }, 0);
    },
    xAxisRange() {
      const dates = Object.keys(this.parsedData.total).sort((a, b) => new Date(a) - new Date(b));

      const firstContributionDate = new Date(dates[0]);
      const lastContributionDate = new Date(dates[dates.length - 1]);

      return getDatesInRange(firstContributionDate, lastContributionDate, toISODateFormat);
    },
    firstContributionDate() {
      return this.xAxisRange[0];
    },
    lastContributionDate() {
      return this.xAxisRange[this.xAxisRange.length - 1];
    },
  },
  watch: {
    selectedMetric() {
      this.fetchStatsForSelectedMetric();
    },
  },
  mounted() {
    this.fetchChartData(this.endpoint);
  },
  methods: {
    ...mapActions(['fetchChartData', 'fetchChartStats']),
    datesToChartData(dates) {
      return this.xAxisRange.map((date) => [date, dates[date] || 0]);
    },
    async fetchStatsForSelectedMetric() {
      if (!this.selectedMetricRequiresStats || this.statsLoaded || this.statsLoading) {
        return;
      }

      const statsLoaded = await this.fetchChartStats(this.endpoint);

      if (!statsLoaded && this.selectedMetricRequiresStats) {
        this.selectedMetric = CONTRIBUTION_METRIC_COMMITS;
      }
    },
    getCommonChartOptions(isMasterChart) {
      return {
        xAxis: {
          type: 'time',
          name: '',
          data: this.xAxisRange,
          axisLabel: {
            formatter: xAxisLabelFormatter,
            showMaxLabel: false,
            showMinLabel: false,
          },
          boundaryGap: false,
          splitNumber: isMasterChart ? 24 : 18,
          // 28 days
          minInterval: 28 * 86400 * 1000,
          min: this.firstContributionDate,
          max: this.lastContributionDate,
        },
      };
    },
    onMasterChartCreated(chart) {
      this.masterChart = chart;
      this.masterChart.setOption({
        dataZoom: [{ type: 'slider', ...this.individualChartZoom }],
      });

      this.masterChart.on(
        'datazoom',
        debounce(() => {
          const [{ startValue, endValue }] = this.masterChart.getOption().dataZoom;
          this.individualChartZoom = { startValue, endValue };
        }, 200),
      );
    },
    visitBranch(selected) {
      const graphsPathPrefix = this.endpoint.match(GRAPHS_PATH_REGEX)?.[0];

      visitUrl(`${graphsPathPrefix}/${selected}`);
    },
  },
};
</script>

<template>
  <div>
    <div v-if="loading" class="gl-pt-13 gl-text-center">
      <gl-loading-icon :inline="true" size="xl" data-testid="loading-app-icon" />
    </div>

    <template v-else-if="showChart">
      <div class="gl-flex">
        <div class="gl-mr-3">
          <ref-selector
            v-model="selectedBranch"
            :project-id="projectId"
            :enabled-ref-types="$options.refTypes"
            :translations="$options.i18n.refSelectorTranslations"
            @input="visitBranch"
          />
        </div>
        <gl-button :href="commitsPath" data-testid="history-button"
          >{{ $options.i18n.history }}
        </gl-button>
      </div>

      <h4 class="gl-mb-2 gl-mt-5">
        {{ __('Commits to') }} <code>{{ branch }}</code>
      </h4>
      <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-3">
        <span>{{
          s__('ContributionAnalytics|Excluding merge commits. Limited to 6,000 commits.')
        }}</span>
        <div class="gl-ml-auto gl-flex gl-items-center gl-gap-3">
          <label for="contributors-metric" class="gl-mb-0">{{
            s__('ContributionAnalytics|Contributions')
          }}</label>
          <gl-form-select
            id="contributors-metric"
            v-model="selectedMetric"
            :options="contributionMetricOptions"
            data-testid="metric-selector"
          />
        </div>
      </div>
      <contributor-area-chart
        v-if="!selectedMetricStatsLoading"
        :key="selectedMetric"
        class="gl-mb-5"
        :data="masterChartData"
        :option="masterChartOptions"
        :height="$options.MASTER_CHART_HEIGHT"
        @created="onMasterChartCreated"
      />
      <div v-else class="gl-py-8 gl-text-center">
        <gl-loading-icon :inline="true" size="lg" data-testid="loading-stats-icon" />
      </div>

      <div v-if="!selectedMetricStatsLoading" class="row">
        <individual-chart
          v-for="(contributor, index) in individualChartsData"
          :key="`${selectedMetric}-${index}`"
          :contributor="contributor"
          :chart-options="individualChartOptions"
          :show-line-changes="selectedMetricRequiresStats"
          :zoom="individualChartZoom"
        />
      </div>
    </template>
  </div>
</template>
