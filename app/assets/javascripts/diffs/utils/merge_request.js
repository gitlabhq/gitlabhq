const endpointRE = /^(\/?(.+\/)+(.+)\/-\/merge_requests\/(\d+)).*$/i;
const SHA1RE = /([a-f0-9]{40})/g;

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
  let namespace;
  let project;
  let id;
  let diffId;
  let startSha;
  const matches = endpointRE.exec(endpoint);

  if (matches) {
    [, mrPath, namespace, project, id] = matches;
    ({ diffId, startSha } = getVersionInfo({ endpoint }));

    namespace = namespace.replace(/\/$/, '');
  }

  return {
    mrPath,
    namespace,
    project,
    id,
    diffId,
    startSha,
  };
}

export function extractFileHash({ input = '' } = {}) {
  const matches = input.match(SHA1RE);

  return matches?.[0];
}
