import { reportToSentry } from '../utils';

const unwrapGroups = (stages) => {
  return stages.map((stage) => {
    const {
      groups: { nodes: groups },
    } = stage;
    return { ...stage, groups };
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

const unwrapStagesWithNeeds = (denodedStages) => {
  const unwrappedNestedGroups = unwrapGroups(denodedStages);

  const nodes = unwrappedNestedGroups.map((node) => {
    const { groups } = node;
    const groupsWithJobs = groups.map((group) => {
      const jobs = unwrapJobWithNeeds(group.jobs.nodes);
      return { ...group, jobs };
    });

    return { ...node, groups: groupsWithJobs };
  });

  return nodes;
};

export { unwrapGroups, unwrapNodesWithName, unwrapJobWithNeeds, unwrapStagesWithNeeds };
