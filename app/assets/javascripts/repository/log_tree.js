import { normalizeData } from 'ee_else_ce/repository/utils/commit';
import axios from '~/lib/utils/axios_utils';
import getCommits from './queries/getCommits.query.graphql';
import getProjectPath from './queries/getProjectPath.query.graphql';
import getRef from './queries/getRef.query.graphql';

let fetchpromise;
let resolvers = [];

export function resolveCommit(commits, path, { resolve, entry }) {
  const commit = commits.find(c => c.filePath === `${path}/${entry.name}` && c.type === entry.type);

  if (commit) {
    resolve(commit);
  }
}

export function fetchLogsTree(client, path, offset, resolver = null) {
  if (resolver) {
    resolvers.push(resolver);
  }

  if (fetchpromise) return fetchpromise;

  const { projectPath } = client.readQuery({ query: getProjectPath });
  const { ref } = client.readQuery({ query: getRef });

  fetchpromise = axios
    .get(
      `${gon.relative_url_root}/${projectPath}/refs/${ref}/logs_tree/${path.replace(/^\//, '')}`,
      {
        params: { format: 'json', offset },
      },
    )
    .then(({ data, headers }) => {
      const headerLogsOffset = headers['more-logs-offset'];
      const { commits } = client.readQuery({ query: getCommits });
      const newCommitData = [...commits, ...normalizeData(data, path)];
      client.writeQuery({
        query: getCommits,
        data: { commits: newCommitData },
      });

      resolvers.forEach(r => resolveCommit(newCommitData, path, r));

      fetchpromise = null;

      if (headerLogsOffset) {
        fetchLogsTree(client, path, headerLogsOffset);
      } else {
        resolvers = [];
      }
    });

  return fetchpromise;
}
