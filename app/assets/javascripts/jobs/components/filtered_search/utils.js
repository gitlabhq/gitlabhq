import { jobStatusValues } from './constants';

// validates query string used for filtered search
// on jobs table to ensure GraphQL query is called correctly
export const validateQueryString = (queryStringObj) => {
  // currently only one token is supported `statuses`
  // this code will need to be expanded as more tokens
  // are introduced

  const filters = Object.keys(queryStringObj);

  if (filters.includes('statuses')) {
    const queryStringStatus = {
      statuses: queryStringObj.statuses.toUpperCase(),
    };

    const found = jobStatusValues.find((status) => status === queryStringStatus.statuses);

    if (found) {
      return queryStringStatus;
    }

    return null;
  }

  return null;
};
