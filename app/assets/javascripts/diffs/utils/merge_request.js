const endpointRE = /^(\/?(.+?)\/(.+?)\/-\/merge_requests\/(\d+)).*$/i;

export function getDerivedMergeRequestInformation({ endpoint } = {}) {
  let mrPath;
  let userOrGroup;
  let project;
  let id;
  const matches = endpointRE.exec(endpoint);

  if (matches) {
    [, mrPath, userOrGroup, project, id] = matches;
  }

  return {
    mrPath,
    userOrGroup,
    project,
    id,
  };
}
