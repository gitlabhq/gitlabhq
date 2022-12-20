const endpointRE = /^(\/?(.+?)\/(.+?)\/-\/merge_requests\/(\d+)).*$/i;

function getVersionInfo({ endpoint } = {}) {
  const dummyRoot = 'https://gitlab.com';
  const endpointUrl = new URL(endpoint, dummyRoot);
  const params = Object.fromEntries(endpointUrl.searchParams.entries());

  const { start_sha: startSha, diff_id: diffId } = params;

  return {
    diffId,
    startSha,
  };
}

export function getDerivedMergeRequestInformation({ endpoint } = {}) {
  let mrPath;
  let userOrGroup;
  let project;
  let id;
  let diffId;
  let startSha;
  const matches = endpointRE.exec(endpoint);

  if (matches) {
    [, mrPath, userOrGroup, project, id] = matches;
    ({ diffId, startSha } = getVersionInfo({ endpoint }));
  }

  return {
    mrPath,
    userOrGroup,
    project,
    id,
    diffId,
    startSha,
  };
}
