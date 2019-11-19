/**
 * @param {Array} queryResults - Array of Result objects
 * @param {Object} defaultConfig - Default chart config values (e.g. lineStyle, name)
 * @returns {Array} The formatted values
 */
// eslint-disable-next-line import/prefer-default-export
export const makeDataSeries = (queryResults, defaultConfig) =>
  queryResults
    .map(result => {
      // NaN values may disrupt avg., max. & min. calculations in the legend, filter them out
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
        series.name = defaultConfig.name;
        Object.keys(result.metric).forEach(templateVar => {
          const value = result.metric[templateVar];
          const regex = new RegExp(`{{\\s*${templateVar}\\s*}}`, 'g');

          series.name = series.name.replace(regex, value);
        });
      }

      return { ...defaultConfig, ...series };
    })
    .filter(series => series !== null);
