<script>
import { __ } from '~/locale';
import { GlLink } from '@gitlab/ui';
import { GlAreaChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';
import { debounceByAnimationFrame, roundOffFloat } from '~/lib/utils/common_utils';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import Icon from '~/vue_shared/components/icon.vue';
import { chartHeight, graphTypes, lineTypes } from '../../constants';
import { makeDataSeries } from '~/helpers/monitor_helper';

let debouncedResize;

export default {
  components: {
    GlAreaChart,
    GlChartSeriesLabel,
    GlLink,
    Icon,
  },
  inheritAttrs: false,
  props: {
    graphData: {
      type: Object,
      required: true,
      validator(data) {
        return (
          Array.isArray(data.queries) &&
          data.queries.filter(query => {
            if (Array.isArray(query.result)) {
              return (
                query.result.filter(res => Array.isArray(res.values)).length === query.result.length
              );
            }
            return false;
          }).length === data.queries.length
        );
      },
    },
    containerWidth: {
      type: Number,
      required: true,
    },
    deploymentData: {
      type: Array,
      required: false,
      default: () => [],
    },
    projectPath: {
      type: String,
      required: true,
    },
    thresholds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      tooltip: {
        title: '',
        content: [],
        commitUrl: '',
        isDeployment: false,
        sha: '',
      },
      width: 0,
      height: chartHeight,
      svgs: {},
      primaryColor: null,
    };
  },
  computed: {
    chartData() {
      // Transforms & supplements query data to render appropriate labels & styles
      // Input: [{ queryAttributes1 }, { queryAttributes2 }]
      // Output: [{ seriesAttributes1 }, { seriesAttributes2 }]
      return this.graphData.queries.reduce((acc, query) => {
        const { appearance } = query;
        const lineType =
          appearance && appearance.line && appearance.line.type
            ? appearance.line.type
            : lineTypes.default;
        const lineWidth =
          appearance && appearance.line && appearance.line.width
            ? appearance.line.width
            : undefined;

        const series = makeDataSeries(query.result, {
          name: this.formatLegendLabel(query),
          lineStyle: {
            type: lineType,
            width: lineWidth,
          },
          areaStyle: {
            opacity:
              appearance && appearance.area && typeof appearance.area.opacity === 'number'
                ? appearance.area.opacity
                : undefined,
          },
        });

        return acc.concat(series);
      }, []);
    },
    chartOptions() {
      return {
        xAxis: {
          name: __('Time'),
          type: 'time',
          axisLabel: {
            formatter: date => dateFormat(date, 'h:MM TT'),
          },
          axisPointer: {
            snap: true,
          },
        },
        yAxis: {
          name: this.yAxisLabel,
          axisLabel: {
            formatter: num => roundOffFloat(num, 3).toString(),
          },
        },
        series: this.scatterSeries,
        dataZoom: this.dataZoomConfig,
      };
    },
    dataZoomConfig() {
      const handleIcon = this.svgs['scroll-handle'];

      return handleIcon ? { handleIcon } : {};
    },
    earliestDatapoint() {
      return this.chartData.reduce((acc, series) => {
        const { data } = series;
        const { length } = data;
        if (!length) {
          return acc;
        }

        const [first] = data[0];
        const [last] = data[length - 1];
        const seriesEarliest = first < last ? first : last;

        return seriesEarliest < acc || acc === null ? seriesEarliest : acc;
      }, null);
    },
    isMultiSeries() {
      return this.tooltip.content.length > 1;
    },
    recentDeployments() {
      return this.deploymentData.reduce((acc, deployment) => {
        if (deployment.created_at >= this.earliestDatapoint) {
          acc.push({
            id: deployment.id,
            createdAt: deployment.created_at,
            sha: deployment.sha,
            commitUrl: `${this.projectPath}/commit/${deployment.sha}`,
            tag: deployment.tag,
            tagUrl: deployment.tag ? `${this.tagsPath}/${deployment.ref.name}` : null,
            ref: deployment.ref.name,
            showDeploymentFlag: false,
          });
        }

        return acc;
      }, []);
    },
    scatterSeries() {
      return {
        type: graphTypes.deploymentData,
        data: this.recentDeployments.map(deployment => [deployment.createdAt, 0]),
        symbol: this.svgs.rocket,
        symbolSize: 14,
        itemStyle: {
          color: this.primaryColor,
        },
      };
    },
    yAxisLabel() {
      return `${this.graphData.y_label}`;
    },
  },
  watch: {
    containerWidth: 'onResize',
  },
  beforeDestroy() {
    window.removeEventListener('resize', debouncedResize);
  },
  created() {
    debouncedResize = debounceByAnimationFrame(this.onResize);
    window.addEventListener('resize', debouncedResize);
    this.setSvg('rocket');
    this.setSvg('scroll-handle');
  },
  methods: {
    formatLegendLabel(query) {
      return `${query.label}`;
    },
    formatTooltipText(params) {
      this.tooltip.title = dateFormat(params.value, 'dd mmm yyyy, h:MMTT');
      this.tooltip.content = [];
      params.seriesData.forEach(seriesData => {
        this.tooltip.isDeployment = seriesData.componentSubType === graphTypes.deploymentData;
        if (this.tooltip.isDeployment) {
          const [deploy] = this.recentDeployments.filter(
            deployment => deployment.createdAt === seriesData.value[0],
          );
          this.tooltip.sha = deploy.sha.substring(0, 8);
          this.tooltip.commitUrl = deploy.commitUrl;
        } else {
          const { seriesName, color } = seriesData;
          // seriesData.value contains the chart's [x, y] value pair
          // seriesData.value[1] is threfore the chart y value
          const value = seriesData.value[1].toFixed(3);

          this.tooltip.content.push({
            name: seriesName,
            value,
            color,
          });
        }
      });
    },
    setSvg(name) {
      getSvgIconPathContent(name)
        .then(path => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch(() => {});
    },
    onChartUpdated(chart) {
      [this.primaryColor] = chart.getOption().color;
    },
    onResize() {
      if (!this.$refs.areaChart) return;
      const { width } = this.$refs.areaChart.$el.getBoundingClientRect();
      this.width = width;
    },
  },
};
</script>

<template>
  <div class="prometheus-graph col-12 col-lg-6">
    <div class="prometheus-graph-header">
      <h5 ref="graphTitle" class="prometheus-graph-title">{{ graphData.title }}</h5>
      <div ref="graphWidgets" class="prometheus-graph-widgets"><slot></slot></div>
    </div>
    <gl-area-chart
      ref="areaChart"
      v-bind="$attrs"
      :data="chartData"
      :option="chartOptions"
      :format-tooltip-text="formatTooltipText"
      :thresholds="thresholds"
      :width="width"
      :height="height"
      @updated="onChartUpdated"
    >
      <template v-if="tooltip.isDeployment">
        <template slot="tooltipTitle">
          {{ __('Deployed') }}
        </template>
        <div slot="tooltipContent" class="d-flex align-items-center">
          <icon name="commit" class="mr-2" />
          <gl-link :href="tooltip.commitUrl">{{ tooltip.sha }}</gl-link>
        </div>
      </template>
      <template v-else>
        <template slot="tooltipTitle">
          <div class="text-nowrap">
            {{ tooltip.title }}
          </div>
        </template>
        <template slot="tooltipContent">
          <div
            v-for="(content, key) in tooltip.content"
            :key="key"
            class="d-flex justify-content-between"
          >
            <gl-chart-series-label :color="isMultiSeries ? content.color : ''">
              {{ content.name }}
            </gl-chart-series-label>
            <div class="prepend-left-32">
              {{ content.value }}
            </div>
          </div>
        </template>
      </template>
    </gl-area-chart>
  </div>
</template>
