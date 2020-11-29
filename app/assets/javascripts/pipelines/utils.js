import { pickBy } from 'lodash';
import { SUPPORTED_FILTER_PARAMETERS } from './constants';

export const validateParams = params => {
  return pickBy(params, (val, key) => SUPPORTED_FILTER_PARAMETERS.includes(key) && val);
};

export const createUniqueJobId = (stageName, jobName) => `${stageName}-${jobName}`;

export const generateJobNeedsDict = ({ jobs }) => {
  const arrOfJobNames = Object.keys(jobs);

  return arrOfJobNames.reduce((acc, value) => {
    const recursiveNeeds = jobName => {
      if (!jobs[jobName]?.needs) {
        return [];
      }

      return jobs[jobName].needs
        .map(job => {
          const { id } = jobs[job];
          // If we already have the needs of a job in the accumulator,
          // then we use the memoized data instead of the recursive call
          // to save some performance.
          const newNeeds = acc[id] ?? recursiveNeeds(job);

          return [id, ...newNeeds];
        })
        .flat(Infinity);
    };

    // To ensure we don't have duplicates job relationship when 2 jobs
    // needed by another both depends on the same jobs, we remove any
    // duplicates from the array.
    const uniqueValues = Array.from(new Set(recursiveNeeds(value)));

    return { ...acc, [jobs[value].id]: uniqueValues };
  }, {});
};
