import { reportToSentry } from '~/ci/utils';
import {
  NEEDS_PROPERTY,
  PREVIOUS_STAGE_JOBS_PROPERTY,
  PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY,
} from '../constants';

const unwrapGroups = (stages) => {
  return stages.map((stage, idx) => {
    const {
      groups: { nodes: groups },
    } = stage;

    /*
      Being peformance conscious here means we don't want to spread and copy the
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
      return { ...job, [prop]: job[prop].nodes.map((item) => item[field] || '') };
    }
    return job;
  });
};

const createPreviousStageJobsOrNeeds = (job) => {
  const previousStageJobs = job[PREVIOUS_STAGE_JOBS_PROPERTY] || [];
  const needs = job[NEEDS_PROPERTY] || [];

  const combined = [...previousStageJobs, ...needs];
  return [...new Set(combined)];
};

const unwrapJobWithNeeds = (denodedJobArray) => {
  const previousStageJobsUnwrapped = unwrapNodesWithName(
    denodedJobArray,
    PREVIOUS_STAGE_JOBS_PROPERTY,
  );

  const needsUnwrapped = unwrapNodesWithName(previousStageJobsUnwrapped, NEEDS_PROPERTY);

  const jobsWithUnion = needsUnwrapped.map((job) => ({
    ...job,
    [PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY]: createPreviousStageJobsOrNeeds(job),
  }));

  return jobsWithUnion;
};

const unwrapStagesWithNeedsAndLookup = (denodedStages) => {
  const unwrappedNestedGroups = unwrapGroups(denodedStages);

  const lookupMap = {};

  const nodes = unwrappedNestedGroups.map(({ node, lookup }) => {
    const { groups } = node;
    const groupsWithJobs = groups.map((group, idx) => {
      const jobs = unwrapJobWithNeeds(group.jobs.nodes);

      lookupMap[group.name] = { ...lookup, groupIdx: idx };
      return { ...group, jobs };
    });

    return { ...node, groups: groupsWithJobs };
  });

  return { stages: nodes, lookup: lookupMap };
};

export { unwrapGroups, unwrapJobWithNeeds, unwrapNodesWithName, unwrapStagesWithNeedsAndLookup };
