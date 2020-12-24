/**
 * This function takes the stages and add the stage name
 * at the group level as `category` to have an easier
 * implementation while constructions nodes with D3
 * @param {Array} stages
 * @returns {Array} - Array of stages with stage name at the group level as `category`
 */
export const unwrapArrayOfJobs = (stages = []) => {
  return stages
    .map(({ name, groups }) => {
      return groups.map((group) => {
        return { category: name, ...group };
      });
    })
    .flat(2);
};

const unwrapGroups = (stages) => {
  return stages.map((stage) => {
    const {
      groups: { nodes: groups },
    } = stage;
    return { ...stage, groups };
  });
};

const unwrapNodesWithName = (jobArray, prop, field = 'name') => {
  return jobArray.map((job) => {
    return { ...job, [prop]: job[prop].nodes.map((item) => item[field]) };
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
