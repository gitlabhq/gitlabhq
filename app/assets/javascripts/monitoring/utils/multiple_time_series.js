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

  let timeSeriesNumber = 1;

  return queryData.result.map((timeSeries) => {
    let metricTag = '';
    let lineColor = '#1f78d1';
    let areaColor = '#8fbce8';

    const timeSeriesScaleX = d3.time.scale()
      .range([0, graphWidth - 70]);

    const timeSeriesScaleY = d3.scale.linear()
      .range([graphHeight - graphHeightOffset, 0]);

    timeSeriesScaleX.domain(d3.extent(timeSeries.values, d => d.time));
    timeSeriesScaleX.ticks(d3.time.minute, 60);
    timeSeriesScaleY.domain([0, maxValueFromSeries.maxValue]);

    const lineFunction = d3.svg.line()
      .interpolate('linear')
      .x(d => timeSeriesScaleX(d.time))
      .y(d => timeSeriesScaleY(d.value));

    const areaFunction = d3.svg.area()
      .interpolate('linear')
      .x(d => timeSeriesScaleX(d.time))
      .y0(graphHeight - graphHeightOffset)
      .y1(d => timeSeriesScaleY(d.value));

    if (queryData.series != null) {
      const timeSeriesMetricLabel = timeSeries.metric[Object.keys(timeSeries.metric)[0]];
      const seriesCustomizationData = _.findWhere(queryData.series[0].series,
                                                  { value: timeSeriesMetricLabel });
      if (seriesCustomizationData != null) {
        metricTag = seriesCustomizationData.value || timeSeriesMetricLabel;
        if (seriesCustomizationData.color != null) {
          [lineColor, areaColor] = pickColor(seriesCustomizationData.color);
        } else {
          [lineColor, areaColor] = pickColor();
        }
      } else {
        metricTag = timeSeriesMetricLabel || `series ${timeSeriesNumber}`;
        [lineColor, areaColor] = pickColor();
      }
    }

    if (timeSeriesNumber <= 5) {
      timeSeriesNumber = timeSeriesNumber += 1;
    } else {
      timeSeriesNumber = 1;
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

