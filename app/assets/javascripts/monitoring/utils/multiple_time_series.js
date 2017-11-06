import d3 from 'd3';
import _ from 'underscore';

const defaultColorPalette = {
  blue: ['#1f78d1', '#8fbce8'],
  orange: ['#fc9403', '#feca81'],
  red: ['#db3b21', '#ed9d90'],
  green: ['#1aaa55', '#8dd5aa'],
  purple: ['#6666c4', '#d1d1f0'],
};

const defaultColorOrder = ['blue', 'orange', 'red', 'green', 'purple'];

export default function createTimeSeries(queryData, graphWidth, graphHeight, graphHeightOffset) {
  let usedColors = [];

  function pickColor(name) {
    let pick;
    if (name && defaultColorPalette[name]) {
      pick = name;
    } else {
      const unusedColors = _.difference(defaultColorOrder, usedColors);
      if (unusedColors.length > 0) {
        pick = unusedColors[0];
      } else {
        usedColors = [];
        pick = defaultColorOrder[0];
      }
    }
    usedColors.push(pick);
    return defaultColorPalette[pick];
  }

  const maxValues = queryData.result.map((timeSeries, index) => {
    const maxValue = d3.max(timeSeries.values.map(d => d.value));
    return {
      maxValue,
      index,
    };
  });

  const maxValueFromSeries = _.max(maxValues, val => val.maxValue);

  return queryData.result.map((timeSeries, timeSeriesNumber) => {
    let metricTag = '';
    let lineColor = '';
    let areaColor = '';

    const timeSeriesScaleX = d3.time.scale()
      .range([0, graphWidth - 70]);

    const timeSeriesScaleY = d3.scale.linear()
      .range([graphHeight - graphHeightOffset, 0]);

    timeSeriesScaleX.domain(d3.extent(timeSeries.values, d => d.time));
    timeSeriesScaleX.ticks(d3.time.minute, 60);
    timeSeriesScaleY.domain([0, maxValueFromSeries.maxValue]);

    const defined = d => !isNaN(d.value) && d.value != null;

    const lineFunction = d3.svg.line()
      .defined(defined)
      .interpolate('linear')
      .x(d => timeSeriesScaleX(d.time))
      .y(d => timeSeriesScaleY(d.value));

    const areaFunction = d3.svg.area()
      .defined(defined)
      .interpolate('linear')
      .x(d => timeSeriesScaleX(d.time))
      .y0(graphHeight - graphHeightOffset)
      .y1(d => timeSeriesScaleY(d.value));

    const timeSeriesMetricLabel = timeSeries.metric[Object.keys(timeSeries.metric)[0]];
    const seriesCustomizationData = queryData.series != null &&
                                    _.findWhere(queryData.series[0].when,
                                    { value: timeSeriesMetricLabel });
    if (seriesCustomizationData != null) {
      metricTag = seriesCustomizationData.value || timeSeriesMetricLabel;
      [lineColor, areaColor] = pickColor(seriesCustomizationData.color);
    } else {
      metricTag = timeSeriesMetricLabel || `series ${timeSeriesNumber + 1}`;
      [lineColor, areaColor] = pickColor();
    }

    return {
      linePath: lineFunction(timeSeries.values),
      areaPath: areaFunction(timeSeries.values),
      timeSeriesScaleX,
      values: timeSeries.values,
      lineColor,
      areaColor,
      metricTag,
    };
  });
}
