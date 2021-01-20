import { graphTypes, symbolSizes, colorValues, annotationsSymbolIcon } from '../../constants';

/**
 * Annotations and deployments are decoration layers on
 * top of the actual chart data. We use a scatter plot to
 * display this information. Each chart has its coordinate
 * system based on data and irrespective of the data, these
 * decorations have to be placed in specific locations.
 * For this reason, annotations have their own coordinate system,
 *
 * As of %12.9, only deployment icons, a type of annotations, need
 * to be displayed on the chart.
 *
 * Annotations and deployments co-exist in the same series as
 * they logically belong together. Annotations are passed as
 * markLines and markPoints while deployments are passed as
 * data points with custom icons.
 */

/**
 * Deployment icons, a type of annotation, are displayed
 * along the [min, max] range at height `pos`.
 */
const annotationsYAxisCoords = {
  min: 0,
  pos: 3, // 3% height of chart's grid
  max: 100,
};

/**
 * Annotation y axis min & max allows the deployment
 * icons to position correctly in the chart
 */
export const annotationsYAxis = {
  show: false,
  min: annotationsYAxisCoords.min,
  max: annotationsYAxisCoords.max,
  axisLabel: {
    // formatter fn required to trigger tooltip re-positioning
    formatter: () => {},
  },
};

/**
 * Fetched list of annotations are parsed into a
 * format the eCharts accepts to draw markLines
 *
 * If Annotation is a single line, the `startingAt` property
 * has a value and the `endingAt` is null. Because annotations
 * only supports lines the `endingAt` value does not exist yet.
 *
 * @param {Object} annotation object
 * @returns {Object} markLine object
 */
export const parseAnnotations = (annotations) =>
  annotations.reduce(
    (acc, annotation) => {
      acc.lines.push({
        xAxis: annotation.startingAt,
        lineStyle: {
          color: colorValues.primaryColor,
        },
      });

      acc.points.push({
        name: 'annotations',
        xAxis: annotation.startingAt,
        yAxis: annotationsYAxisCoords.min,
        tooltipData: {
          title: annotation.startingAt,
          content: annotation.description,
        },
      });

      return acc;
    },
    { lines: [], points: [] },
  );

/**
 * This method generates a decorative series that has
 * deployments as data points with custom icons and
 * annotations as markLines and markPoints
 *
 * @param {Array} deployments deployments data
 * @returns {Object} annotation series object
 */
export const generateAnnotationsSeries = ({ deployments = [], annotations = [] } = {}) => {
  // deployment data points
  const data = deployments.map((deployment) => {
    return {
      name: 'deployments',
      value: [deployment.createdAt, annotationsYAxisCoords.pos],
      // style options
      symbol: deployment.icon,
      symbolSize: symbolSizes.default,
      itemStyle: {
        color: deployment.color,
      },
      // metadata that are accessible in `formatTooltipText` method
      tooltipData: {
        sha: deployment.sha.substring(0, 8),
        commitUrl: deployment.commitUrl,
      },
    };
  });

  const parsedAnnotations = parseAnnotations(annotations);

  // markLine option draws the annotations dotted line
  const markLine = {
    symbol: 'none',
    silent: true,
    data: parsedAnnotations.lines,
  };

  // markPoints are the arrows under the annotations lines
  const markPoint = {
    symbol: annotationsSymbolIcon,
    symbolSize: '8',
    symbolOffset: [0, ' 60%'],
    data: parsedAnnotations.points,
  };

  return {
    name: 'annotations',
    type: graphTypes.annotationsData,
    yAxisIndex: 1, // annotationsYAxis index
    data,
    markLine,
    markPoint,
  };
};
