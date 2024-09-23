<script>
import { GlChart } from '@gitlab/ui/dist/charts';
import { DATA_VIZ_BLUE_500 } from '@gitlab/ui/src/tokens/build/js/tokens';
import { hexToRgba } from '@gitlab/ui/dist/utils/utils';
import { isNumber } from 'lodash';
import { newDate } from '~/lib/utils/datetime/date_calculation_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { logError } from '~/lib/logger';

function parseTimelineData(timelineData) {
  const xData = [];
  const yData = [];
  const invalidDataPoints = [];
  timelineData.forEach((f) => {
    let rawDate;
    let count;

    if (Array.isArray(f)) {
      [rawDate, count] = f;
    } else if (f.count !== undefined && f.time !== undefined) {
      rawDate = f.time;
      count = f.count;
    }
    if (rawDate !== undefined && count !== undefined) {
      // dates/timestamps are in seconds
      const date = isNumber(rawDate) ? rawDate * 1000 : rawDate;
      xData.push(localeDateFormat.asDateTimeFull.format(newDate(date)));
      yData.push(count);
    } else {
      invalidDataPoints.push(f);
    }
  });
  if (invalidDataPoints.length > 0) {
    // only log up to 5 invalid data points to reduce log size
    logError(`Found invalid data points ${invalidDataPoints.slice(0, 5)}`);
  }
  return { xData, yData };
}

export default {
  components: {
    GlChart,
  },
  props: {
    timelineData: {
      /**
       * Array items can be:
       *   touples: [a_date: string | number, a_count: number]
       *   objects: {time: a_date, count: a_count}: {time: string | number, count: number}
       *
       * Dates can either be string or number/timestamp.
       * When dates are timestamps, they are expected in seconds.
       *
       */
      type: Array,
      required: true,
      validator(value) {
        for (const item of value) {
          if (Array.isArray(item)) {
            if (item.length !== 2 || !isNumber(item[1])) {
              return false;
            }
          } else if (typeof item === 'object') {
            if (!('time' in item) || !('count' in item)) {
              return false;
            }
          } else {
            return false;
          }
        }
        return true;
      },
    },
    height: {
      type: Number,
      required: true,
    },
  },
  computed: {
    chartOptions() {
      if (!this.timelineData) {
        return {};
      }
      const { xData, yData } = parseTimelineData(this.timelineData);

      return {
        xAxis: {
          type: 'category',
          data: xData,
          show: true,
          axisTick: {
            show: false,
          },
          axisLabel: {
            show: false,
          },
          axisLine: {
            show: true,
            lineStyle: {
              width: 1,
              color: '#ececec',
            },
          },
        },
        yAxis: {
          type: 'value',
          show: false,
        },
        series: [
          {
            data: yData,
            type: 'bar',
            itemStyle: { color: hexToRgba(DATA_VIZ_BLUE_500, 0.5) },
          },
        ],
        tooltip: {
          trigger: 'axis',
          axisPointer: {
            type: 'shadow',
          },
        },
      };
    },
  },
};
</script>

<template>
  <gl-chart v-if="timelineData" :options="chartOptions" :height="height" />
</template>
