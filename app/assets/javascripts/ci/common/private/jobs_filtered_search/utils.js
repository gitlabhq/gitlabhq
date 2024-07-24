import { jobStatusValues, jobRunnerTypeValues } from './constants';

// validates query string used for filtered search
// on jobs table to ensure GraphQL query is called correctly
export const validateQueryString = (queryStringObj) => {
  return Object.entries(queryStringObj).reduce((acc, [queryStringKey, queryStringValue]) => {
    switch (queryStringKey) {
      case 'statuses': {
        const statusValue = queryStringValue.toUpperCase();
        const statusValueValid = jobStatusValues.includes(statusValue);
        return statusValueValid ? { ...acc, statuses: statusValue } : acc;
      }
      case 'runnerTypes': {
        const runnerTypesValue = queryStringValue.toUpperCase();
        const runnerTypesValueValid = jobRunnerTypeValues.includes(runnerTypesValue);
        return runnerTypesValueValid ? { ...acc, runnerTypes: runnerTypesValue } : acc;
      }
      case 'name': {
        return { ...acc, name: queryStringValue };
      }
      default:
        return acc;
    }
  }, null);
};
