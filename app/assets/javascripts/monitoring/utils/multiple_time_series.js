import d3 from 'd3';
import _ from 'underscore';

export default function createTimeSeries(seriesData, graphWidth, graphHeight, graphHeightOffset) {
  const maxValues = seriesData.map((timeSeries, index) => {
    const maxValue = d3.max(timeSeries.values.map(d => d.value));
    return {
      maxValue,
      index,
    };
  });

  const maxValueFromSeries = _.max(maxValues, val => val.maxValue);

  let timeSeriesNumber = 1;
  let lineColor = '#1f78d1';
  let areaColor = '#8fbce8';
  const lineColors = ['#1f78d1', '#fc9403', '#db3b21', '#1aaa55', '#6666c4'];
  const areaColors = ['#8fbce8', '#feca81', '#ed9d90', '#8dd5aa', '#d1d1f0'];

  return seriesData.map((timeSeries) => {
    const timeSeriesScaleX = d3.time.scale()
      .range([0, graphWidth - 70]);

    const timeSeriesScaleY = d3.scale.linear()
      .range([graphHeight - graphHeightOffset, 0]);

    timeSeriesScaleX.domain(d3.extent(timeSeries.values, d => d.time));
    timeSeriesScaleY.domain([0, maxValueFromSeries.maxValue]);

    const lineFunction = d3.svg.line()
      .x(d => timeSeriesScaleX(d.time))
      .y(d => timeSeriesScaleY(d.value));

    const areaFunction = d3.svg.area()
      .x(d => timeSeriesScaleX(d.time))
      .y0(graphHeight - graphHeightOffset)
      .y1(d => timeSeriesScaleY(d.value))
      .interpolate('linear');

    lineColor = lineColors[timeSeriesNumber - 1];
    areaColor = areaColors[timeSeriesNumber - 1];

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
    };
  });
}
