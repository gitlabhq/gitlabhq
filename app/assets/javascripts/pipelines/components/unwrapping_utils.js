import { reportToSentry } from '../utils';

const unwrapGroups = (stages) => {
  return stages.map((stage, idx) => {
    const {
      groups: { nodes: groups },
    } = stage;
    return { node: { ...stage, groups }, lookup: { stageIdx: idx } };
  });
};

const unwrapNodesWithName = (jobArray, prop, field = 'name') => {
  if (jobArray.length < 1) {
    reportToSentry('unwrapping_utils', 'undefined_job_hunt, array empty from backend');
  }

  return jobArray.map((job) => {
    return { ...job, [prop]: job[prop].nodes.map((item) => item[field] || '') };
  });
};

const unwrapJobWithNeeds = (denodedJobArray) => {
  return unwrapNodesWithName(denodedJobArray, 'needs');
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
