import d3 from 'd3';
import _ from 'underscore';

function pickColorFromNameNumber(colorName, colorNumber) {
  let lineColor = '';
  let areaColor = '';
  const color = colorName != null ? colorName : colorNumber;
  switch (color) {
    case 'blue':
    case 1:
      lineColor = '#1f78d1';
      areaColor = '#8fbce8';
      break;
    case 'orange':
    case 2:
      lineColor = '#fc9403';
      areaColor = '#feca81';
      break;
    case 'red':
    case 3:
      lineColor = '#db3b21';
      areaColor = '#ed9d90';
      break;
    case 'green':
    case 4:
      lineColor = '#1aaa55';
      areaColor = '#8dd5aa';
      break;
    case 'purple':
    case 5:
      lineColor = '#6666c4';
      areaColor = '#d1d1f0';
      break;
    default:
      lineColor = '#1f78d1';
      areaColor = '#8fbce8';
      break;
  }

  return {
    lineColor,
    areaColor,
  };
}

export default function createTimeSeries(queryData, graphWidth, graphHeight, graphHeightOffset) {
  const maxValues = queryData.result.map((timeSeries, index) => {
    const maxValue = d3.max(timeSeries.values.map(d => d.value));
    return {
      maxValue,
      index,
    };
  });

  const maxValueFromSeries = _.max(maxValues, val => val.maxValue);

  let timeSeriesNumber = 1;

  return queryData.result.map((timeSeries, index) => {
    let metricTag = '';
    let pathColors = null;
    const timeSeriesScaleX = d3.time.scale()
      .range([0, graphWidth - 70]);

    const timeSeriesScaleY = d3.scale.linear()
      .range([graphHeight - graphHeightOffset, 0]);

    timeSeriesScaleX.domain(d3.extent(timeSeries.values, d => d.time));
    timeSeriesScaleX.ticks(d3.time.minute, 60);
    timeSeriesScaleY.domain([0, maxValueFromSeries.maxValue]);

    const lineFunction = d3.svg.line()
      .interpolate('step-before')
      .x(d => timeSeriesScaleX(d.time))
      .y(d => timeSeriesScaleY(d.value));

    const areaFunction = d3.svg.area()
      .interpolate('step-before')
      .x(d => timeSeriesScaleX(d.time))
      .y0(graphHeight - graphHeightOffset)
      .y1(d => timeSeriesScaleY(d.value));

    if (queryData.series != null) {
      const seriesCustomizationData = queryData.series[index];
      const timeSeriesMetricLabel = timeSeries.metric[Object.keys(timeSeries.metric)[0]];
      if (seriesCustomizationData != null) {
        metricTag = seriesCustomizationData.value || timeSeriesMetricLabel;
        if (seriesCustomizationData.color != null) {
          pathColors = pickColorFromNameNumber(seriesCustomizationData.color.toLowerCase(), null);
        }
      } else {
        metricTag = timeSeriesMetricLabel || `series ${timeSeriesNumber}`;
      }
    }

    if (pathColors == null) {
      pathColors = pickColorFromNameNumber(null, timeSeriesNumber);
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
      ...pathColors,
      metricTag,
    };
  });
}

