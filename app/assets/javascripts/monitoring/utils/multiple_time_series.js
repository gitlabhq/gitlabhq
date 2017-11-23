import _ from 'underscore';
import {
  scaleLinear as d3ScaleLinear,
  scaleTime as d3ScaleTime,
  line as d3Line,
  area as d3Area,
  extent as d3Extent,
  max as d3Max,
  timeMinute as d3TimeMinute,
  curveLinear as d3CurveLinear,
} from '../../common_d3/index';

const defaultColorPalette = {
  blue: ['#1f78d1', '#8fbce8'],
  orange: ['#fc9403', '#feca81'],
  red: ['#db3b21', '#ed9d90'],
  green: ['#1aaa55', '#8dd5aa'],
  purple: ['#6666c4', '#d1d1f0'],
};

const defaultColorOrder = ['blue', 'orange', 'red', 'green', 'purple'];

const defaultStyleOrder = ['solid', 'dashed', 'dotted'];

function queryTimeSeries(query, graphWidth, graphHeight, graphHeightOffset, xDom, yDom, lineStyle) {
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

  return query.result.map((timeSeries, timeSeriesNumber) => {
    let metricTag = '';
    let lineColor = '';
    let areaColor = '';

    const timeSeriesScaleX = d3ScaleTime()
      .range([0, graphWidth - 70]);

    const timeSeriesScaleY = d3ScaleLinear()
      .range([graphHeight - graphHeightOffset, 0]);

    timeSeriesScaleX.domain(xDom);
    timeSeriesScaleX.ticks(d3TimeMinute, 60);
    timeSeriesScaleY.domain(yDom);

    const defined = d => !isNaN(d.value) && d.value != null;

    const lineFunction = d3Line()
      .defined(defined)
      .curve(d3CurveLinear) // d3 v4 uses curbe instead of interpolate
      .x(d => timeSeriesScaleX(d.time))
      .y(d => timeSeriesScaleY(d.value));

    const areaFunction = d3Area()
      .defined(defined)
      .curve(d3CurveLinear)
      .x(d => timeSeriesScaleX(d.time))
      .y0(graphHeight - graphHeightOffset)
      .y1(d => timeSeriesScaleY(d.value));

    const timeSeriesMetricLabel = timeSeries.metric[Object.keys(timeSeries.metric)[0]];
    const seriesCustomizationData = query.series != null &&
      _.findWhere(query.series[0].when, { value: timeSeriesMetricLabel });

    if (seriesCustomizationData) {
      metricTag = seriesCustomizationData.value || timeSeriesMetricLabel;
      [lineColor, areaColor] = pickColor(seriesCustomizationData.color);
    } else {
      metricTag = timeSeriesMetricLabel || `series ${timeSeriesNumber + 1}`;
      [lineColor, areaColor] = pickColor();
    }

    if (query.track) {
      metricTag += ` - ${query.track}`;
    }

    return {
      linePath: lineFunction(timeSeries.values),
      areaPath: areaFunction(timeSeries.values),
      timeSeriesScaleX,
      values: timeSeries.values,
      lineStyle,
      lineColor,
      areaColor,
      metricTag,
    };
  });
}

export default function createTimeSeries(queries, graphWidth, graphHeight, graphHeightOffset) {
  const allValues = queries.reduce((allQueryResults, query) => allQueryResults.concat(
    query.result.reduce((allResults, result) => allResults.concat(result.values), []),
  ), []);

  const xDom = d3Extent(allValues, d => d.time);
  const yDom = [0, d3Max(allValues.map(d => d.value))];

  return queries.reduce((series, query, index) => {
    const lineStyle = defaultStyleOrder[index % defaultStyleOrder.length];
    return series.concat(
      queryTimeSeries(query, graphWidth, graphHeight, graphHeightOffset, xDom, yDom, lineStyle),
    );
  }, []);
}
