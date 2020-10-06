import { pickBy } from 'lodash';
import { SUPPORTED_FILTER_PARAMETERS } from './constants';

export const validateParams = params => {
  return pickBy(params, (val, key) => SUPPORTED_FILTER_PARAMETERS.includes(key) && val);
};

/**
 * This function takes a json payload that comes from a yml
 * file converted to json through `jsyaml` library. Because we
 * naively convert the entire yaml to json, some keys (like `includes`)
 * are irrelevant to rendering the graph and must be removed. We also
 * restructure the data to have the structure from an API response for the
 * pipeline data.
 * @param {Object} jsonData
 * @returns {Array} - Array of stages containing all jobs
 */
export const preparePipelineGraphData = jsonData => {
  const jsonKeys = Object.keys(jsonData);
  const jobNames = jsonKeys.filter(job => jsonData[job]?.stage);
  // Creates an object with only the valid jobs
  const jobs = jsonKeys.reduce((acc, val) => {
    if (jobNames.includes(val)) {
      return { ...acc, [val]: { ...jsonData[val] } };
    }
    return { ...acc };
  }, {});

  // We merge both the stages from the "stages" key in the yaml and the stage associated
  // with each job to show the user both the stages they explicitly defined, and those
  // that they added under jobs. We also remove duplicates.
  const jobStages = jobNames.map(job => jsonData[job].stage);
  const userDefinedStages = jsonData?.stages ?? [];

  // The order is important here. We always show the stages in order they were
  // defined in the `stages` key first, and then stages that are under the jobs.
  const stages = Array.from(new Set([...userDefinedStages, ...jobStages]));

  const arrayOfJobsByStage = stages.map(val => {
    return jobNames.filter(job => {
      return jsonData[job].stage === val;
    });
  });

  const pipelineData = stages.map((stage, index) => {
    const stageJobs = arrayOfJobsByStage[index];
    return {
      name: stage,
      groups: stageJobs.map(job => {
        return { name: job, jobs: [{ ...jsonData[job] }] };
      }),
    };
  });

  return { stages: pipelineData, jobs };
};

export const createUniqueJobId = (stageName, jobName) => `${stageName}-${jobName}`;
