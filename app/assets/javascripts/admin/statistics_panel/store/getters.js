/**
 * Merges the statisticsLabels with the state's data
 * and returns an array of the following form:
 * [{ key: "forks", label: "Forks", value: 50 }]
 */
export const getStatistics = (state) => (labels) =>
  Object.keys(labels).map((key) => {
    const result = {
      key,
      label: labels[key],
      value: state.statistics && state.statistics[key] ? state.statistics[key] : null,
    };
    return result;
  });
