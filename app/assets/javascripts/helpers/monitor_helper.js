/* eslint-disable import/prefer-default-export */
import _ from 'underscore';

/**
 * @param {Array} queryResults - Array of Result objects
 * @param {Object} defaultConfig - Default chart config values (e.g. lineStyle, name)
 * @returns {Array} The formatted values
 */
export const makeDataSeries = (queryResults, defaultConfig) =>
  queryResults
    .map(result => {
      const data = result.values.filter(([, value]) => !Number.isNaN(value));
      if (!data.length) {
        return null;
      }
      const relevantMetric = defaultConfig.name.toLowerCase().replace(' ', '_');
      const name = result.metric[relevantMetric];
      const series = { data };
      if (name) {
        series.name = `${defaultConfig.name}: ${name}`;
      } else {
        const template = _.template(defaultConfig.name, {
          interpolate: /\{\{(.+?)\}\}/g,
        });
        series.name = template(result.metric);
      }

      return { ...defaultConfig, ...series };
    })
    .filter(series => series !== null);
