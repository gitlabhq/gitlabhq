const unwrapPipelineData = (mainPipelineId, data) => {
  if (!data?.project?.pipeline) {
    return null;
  }

  const {
    id,
    upstream,
    downstream,
    stages: { nodes: stages },
  } = data.project.pipeline;

  const unwrappedNestedGroups = stages.map(stage => {
    const {
      groups: { nodes: groups },
    } = stage;
    return { ...stage, groups };
  });

  const nodes = unwrappedNestedGroups.map(({ name, status, groups }) => {
    const groupsWithJobs = groups.map(group => {
      const jobs = group.jobs.nodes.map(job => {
        const { needs } = job;
        return { ...job, needs: needs.nodes.map(need => need.name) };
      });

      return { ...group, jobs };
    });

    return { name, status, groups: groupsWithJobs };
  });

  const addMulti = pipeline => {
    return { ...pipeline, multiproject: mainPipelineId !== pipeline.id };
  };

  return {
    id,
    stages: nodes,
    upstream: upstream ? [upstream].map(addMulti) : [],
    downstream: downstream ? downstream.map(addMulti) : [],
  };
};

export { unwrapPipelineData };
