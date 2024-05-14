<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { debounce, uniq } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
import { getDatesInRange } from '~/lib/utils/datetime_utility';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import { xAxisLabelFormatter, dateFormatter } from '../utils';
import { MASTER_CHART_HEIGHT } from '../constants';
import ContributorAreaChart from './contributor_area_chart.vue';
import IndividualChart from './individual_chart.vue';

const GRAPHS_PATH_REGEX = /^(.*?)\/-\/graphs/g;

export default {
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
    getSvgIconPathContent: {
      type: Function,
      required: false,
      default: getSvgIconPathContent,
    },
  },
  refTypes: [REF_TYPE_BRANCHES, REF_TYPE_TAGS],
  data() {
    return {
      masterChart: null,
      individualCharts: [],
      individualChartZoom: {},
      svgs: {},
      selectedBranch: this.branch,
    };
  },
  computed: {
    ...mapState(['chartData', 'loading']),
    ...mapGetters(['showChart', 'parsedData']),
    masterChartData() {
      const data = {};
      this.xAxisRange.forEach((date) => {
        data[date] = this.parsedData.total[date] || 0;
      });
      return [
        {
          name: __('Commits'),
          data: Object.entries(data),
        },
      ];
    },
    masterChartOptions() {
      return {
        ...this.getCommonChartOptions(true),
        yAxis: {
          name: __('Number of commits'),
        },
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
          return {
            name: author.name,
            email,
            commits: author.commits,
            dates: [
              {
                name: __('Commits'),
                data: this.xAxisRange.map((date) => [date, author.dates[date] || 0]),
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
          name: __('Commits'),
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
      return this.individualChartsData.reduce((acc, item) => {
        const values = item.dates[0].data.map((value) => value[1]);
        return Math.max(acc, ...values);
      }, 0);
    },
    xAxisRange() {
      const dates = Object.keys(this.parsedData.total).sort((a, b) => new Date(a) - new Date(b));

      const firstContributionDate = new Date(dates[0]);
      const lastContributionDate = new Date(dates[dates.length - 1]);

      return getDatesInRange(firstContributionDate, lastContributionDate, dateFormatter);
    },
    firstContributionDate() {
      return this.xAxisRange[0];
    },
    lastContributionDate() {
      return this.xAxisRange[this.xAxisRange.length - 1];
    },
    charts() {
      return uniq(this.individualCharts);
    },
  },
  mounted() {
    this.fetchChartData(this.endpoint);
  },
  methods: {
    ...mapActions(['fetchChartData']),
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
    setSvg(name) {
      return this.getSvgIconPathContent(name)
        .then((path) => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch(() => {});
    },
    onMasterChartCreated(chart) {
      this.masterChart = chart;
      this.setSvg('scroll-handle')
        .then(() => {
          this.masterChart.setOption({
            dataZoom: [
              {
                type: 'slider',
                handleIcon: this.svgs['scroll-handle'],
              },
            ],
          });
        })
        .catch(() => {});

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
    <div v-if="loading" class="gl-text-center gl-pt-13">
      <gl-loading-icon :inline="true" size="xl" data-testid="loading-app-icon" />
    </div>

    <template v-else-if="showChart">
      <div class="gl-border-b gl-border-gray-100 gl-mb-6 gl-bg-gray-10 gl-py-5">
        <div class="gl-display-flex">
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
      </div>

      <h4 class="gl-mb-2 gl-mt-5">{{ __('Commits to') }} {{ branch }}</h4>
      <span>{{ __('Excluding merge commits. Limited to 6,000 commits.') }}</span>
      <contributor-area-chart
        class="gl-mb-5"
        :data="masterChartData"
        :option="masterChartOptions"
        :height="$options.MASTER_CHART_HEIGHT"
        @created="onMasterChartCreated"
      />

      <div class="row">
        <individual-chart
          v-for="(contributor, index) in individualChartsData"
          :key="index"
          :contributor="contributor"
          :chart-options="individualChartOptions"
          :zoom="individualChartZoom"
        />
      </div>
    </template>
  </div>
</template>
