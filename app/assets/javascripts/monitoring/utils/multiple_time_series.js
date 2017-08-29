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

    return {
      linePath: lineFunction(timeSeries.values),
      areaPath: areaFunction(timeSeries.values),
      timeSeriesScaleX,
      values: timeSeries.values,
    };
  });
}
