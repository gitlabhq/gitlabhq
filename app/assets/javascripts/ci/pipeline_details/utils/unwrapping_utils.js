import { reportToSentry } from '~/ci/utils';
import { NEEDS_PROPERTY, ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY } from '../constants';

/**
 * Extract all job names from a stage's groups
 * @param {Array} groups - Array of groups from a stage
 * @returns {Array} - Array of job names
 */
const extractJobNamesFromGroups = (groups = []) => {
  return groups.flatMap((g) => (g.jobs || []).map((j) => j.name));
};

const unwrapGroups = (stages) => {
  return stages.map((stage, idx) => {
    const {
      groups: { nodes: groups },
    } = stage;

    /*
      Being performance conscious here means we don't want to spread and copy the
      group value just to add one parameter.
    */
    /* eslint-disable no-param-reassign */
    const groupsWithStageName = groups.map((group) => {
      group.stageName = stage.name;
      return group;
    });
    /* eslint-enable no-param-reassign */

    return { node: { ...stage, groups: groupsWithStageName }, lookup: { stageIdx: idx } };
  });
};

const unwrapNodesWithName = (jobArray, prop, field = 'name') => {
  if (jobArray.length < 1) {
    reportToSentry('unwrapping_utils', 'undefined_job_hunt, array empty from backend');
  }

  return jobArray.map((job) => {
    if (job[prop]) {
      const items = job[prop].nodes || job[prop];
      return { ...job, [prop]: items.map((item) => item[field] || '') };
    }
    return job;
  });
};

const unwrapJobWithNeeds = (denodedJobArray, previousStageJobNames = []) => {
  const needsUnwrapped = unwrapNodesWithName(denodedJobArray, NEEDS_PROPERTY);

  return needsUnwrapped.map((job) => {
    const needs = job[NEEDS_PROPERTY] || [];

    const unionNeeds = [...new Set([...previousStageJobNames, ...needs])];

    return {
      ...job,
      [NEEDS_PROPERTY]: needs,
      [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: unionNeeds,
    };
  });
};

const unwrapStagesWithNeedsAndLookup = (denodedStages) => {
  const unwrappedNestedGroups = unwrapGroups(denodedStages);

  const lookupMap = {};
  const processedStages = [];

  const nodes = unwrappedNestedGroups.map(({ node, lookup }, stageIndex) => {
    const { groups } = node;

    // Get all job names from the previous stage for non-DAG jobs
    const previousStage = processedStages[stageIndex - 1];
    const previousStageJobNames = previousStage
      ? extractJobNamesFromGroups(previousStage.groups)
      : [];

    const groupsWithJobs = groups.map((group, idx) => {
      const jobs = unwrapJobWithNeeds(group.jobs.nodes, previousStageJobNames);

      lookupMap[group.name] = { ...lookup, groupIdx: idx };
      return { ...group, jobs };
    });

    const processedNode = { ...node, groups: groupsWithJobs };
    processedStages.push(processedNode);

    return processedNode;
  });

  return { stages: nodes, lookup: lookupMap };
};

/**
 * Unwrap stages from mutation format (without .nodes wrappers)
 * @param {Array} stages - Stages array from ciLint mutation
 * @returns {Array} - Stages with unwrapped job needs
 */
const unwrapStagesFromMutation = (stages) => {
  return stages.map((stage, stageIndex) => {
    // Get all job names from the previous stage for non-DAG jobs
    const previousStageJobNames =
      stageIndex > 0 ? extractJobNamesFromGroups(stages[stageIndex - 1].groups) : [];

    return {
      ...stage,
      groups: (stage.groups || []).map((group) => ({
        ...group,
        jobs: unwrapJobWithNeeds(group.jobs || [], previousStageJobNames),
      })),
    };
  });
};

export {
  unwrapGroups,
  unwrapJobWithNeeds,
  unwrapNodesWithName,
  unwrapStagesWithNeedsAndLookup,
  unwrapStagesFromMutation,
};
