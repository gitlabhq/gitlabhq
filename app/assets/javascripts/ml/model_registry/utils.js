export function convertCandidateFromGraphql(graphqlCandidate) {
  const { iid, eid, status, ciJob } = graphqlCandidate;
  const links = graphqlCandidate._links;

  let ciJobValues = null;

  if (ciJob) {
    let userInfo = null;
    let mergeRequestInfo = null;
    const user = ciJob?.pipeline.user;
    const mr = ciJob?.pipeline.mergeRequest;

    if (user) {
      userInfo = {
        avatar: user.avatarUrl,
        path: user.webUrl,
        username: user.username,
        name: user.name,
      };
    }

    if (mr) {
      mergeRequestInfo = {
        title: mr.title,
        path: mr.webUrl,
        iid: mr.iid,
      };
    }

    ciJobValues = {
      name: ciJob.name,
      path: ciJob.webPath,
      user: userInfo,
      mergeRequest: mergeRequestInfo,
    };
  }

  return {
    info: {
      iid,
      eid,
      status,
      experimentName: '',
      pathToExperiment: '',
      pathToArtifact: links.artifactPath,
      path: links.showPath,
      ciJob: ciJobValues,
    },
    metrics: graphqlCandidate.metrics.nodes,
    params: graphqlCandidate.params.nodes,
    metadata: graphqlCandidate.metadata.nodes,
  };
}
