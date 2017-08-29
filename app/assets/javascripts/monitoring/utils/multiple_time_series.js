import d3 from 'd3';

export default function createTimeSeries(seriesData, graphWidth, graphHeight, graphHeightOffset) {
  return seriesData.map((timeSeries) => {
    const timeSeriesScaleX = d3.time.scale()
      .range([0, graphWidth - 70]);

    const timeSeriesScaleY = d3.scale.linear()
      .range([graphHeight - graphHeightOffset, 0]);

    timeSeriesScaleX.domain(d3.extent(timeSeries.values, d => d.time));
    timeSeriesScaleY.domain([0, d3.max(timeSeries.values.map(d => d.value))]);

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
      timeSeriesScaleY,
      values: timeSeries.values,
    };
  });
}
