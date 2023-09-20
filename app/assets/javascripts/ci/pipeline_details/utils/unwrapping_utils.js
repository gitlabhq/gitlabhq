import { reportToSentry } from '~/ci/utils';
import { EXPLICIT_NEEDS_PROPERTY, NEEDS_PROPERTY } from '../constants';

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

const unwrapJobWithNeeds = (denodedJobArray) => {
  const explicitNeedsUnwrapped = unwrapNodesWithName(denodedJobArray, EXPLICIT_NEEDS_PROPERTY);
  return unwrapNodesWithName(explicitNeedsUnwrapped, NEEDS_PROPERTY);
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

const unwrapStagesWithNeeds = (denodedStages) => {
  return unwrapStagesWithNeedsAndLookup(denodedStages).stages;
};

export {
  unwrapGroups,
  unwrapJobWithNeeds,
  unwrapNodesWithName,
  unwrapStagesWithNeeds,
  unwrapStagesWithNeedsAndLookup,
};
