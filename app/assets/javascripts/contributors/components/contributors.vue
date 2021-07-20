<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { debounce, uniq } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import { getDatesInRange } from '~/lib/utils/datetime_utility';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { __ } from '~/locale';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';
import { xAxisLabelFormatter, dateFormatter } from '../utils';

export default {
  components: {
    GlAreaChart,
    GlLoadingIcon,
    ResizableChartContainer,
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
  },
  data() {
    return {
      masterChart: null,
      individualCharts: [],
      svgs: {},
      masterChartHeight: 264,
      individualChartHeight: 216,
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
      return getSvgIconPathContent(name)
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
      this.masterChart.on('datazoom', debounce(this.setIndividualChartsZoom, 200));
    },
    onIndividualChartCreated(chart) {
      this.individualCharts.push(chart);
    },
    setIndividualChartsZoom(options) {
      this.charts.forEach((chart) =>
        chart.setOption(
          {
            dataZoom: {
              start: options.start,
              end: options.end,
              show: false,
            },
          },
          { lazyUpdate: true },
        ),
      );
    },
  },
};
</script>

<template>
  <div>
    <div v-if="loading" class="contributors-loader text-center">
      <gl-loading-icon :inline="true" size="xl" />
    </div>

    <div v-else-if="showChart" class="contributors-charts">
      <h4 class="gl-mb-2 gl-mt-5">{{ __('Commits to') }} {{ branch }}</h4>
      <span>{{ __('Excluding merge commits. Limited to 6,000 commits.') }}</span>
      <resizable-chart-container>
        <template #default="{ width }">
          <gl-area-chart
            class="gl-mb-5"
            :width="width"
            :data="masterChartData"
            :option="masterChartOptions"
            :height="masterChartHeight"
            @created="onMasterChartCreated"
          />
        </template>
      </resizable-chart-container>

      <div class="row">
        <div
          v-for="(contributor, index) in individualChartsData"
          :key="index"
          class="col-lg-6 col-12 gl-my-5"
        >
          <h4 class="gl-mb-2 gl-mt-0">{{ contributor.name }}</h4>
          <p class="gl-mb-3">
            {{ n__('%d commit', '%d commits', contributor.commits) }} ({{ contributor.email }})
          </p>
          <resizable-chart-container>
            <template #default="{ width }">
              <gl-area-chart
                :width="width"
                :data="contributor.dates"
                :option="individualChartOptions"
                :height="individualChartHeight"
                @created="onIndividualChartCreated"
              />
            </template>
          </resizable-chart-container>
        </div>
      </div>
    </div>
  </div>
</template>
