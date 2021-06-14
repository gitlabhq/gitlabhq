import produce from 'immer';
import { normalizeData } from 'ee_else_ce/repository/utils/commit';
import axios from '~/lib/utils/axios_utils';
import commitsQuery from './queries/commits.query.graphql';
import projectPathQuery from './queries/project_path.query.graphql';
import refQuery from './queries/ref.query.graphql';

const fetchpromises = {};
const resolvers = {};
let maxOffset;
let nextOffset;
let currentPath;

function setNextOffset(offset) {
  nextOffset = offset || null;
}

export function resolveCommit(commits, path, { resolve, entry }) {
  const commit = commits.find(
    (c) => c.filePath === `${path}/${entry.name}` && c.type === entry.type,
  );

  if (commit) {
    resolve(commit);
  }
}

export function fetchLogsTree(client, path, offset, resolver = null, _maxOffset = null) {
  if (_maxOffset) {
    maxOffset = _maxOffset;
  }

  if (!currentPath || currentPath !== path) {
    // ensures the nextOffset is reset if the user changed directories
    setNextOffset(null);
  }

  currentPath = path;

  const offsetNumber = Number(offset);

  if (!nextOffset && offsetNumber > maxOffset) {
    setNextOffset(offsetNumber - 25); // ensures commit data is fetched for newly added rows that need data from the previous request (requests are made in batches of 25).
    return Promise.resolve();
  }

  if (resolver) {
    if (!resolvers[path]) {
      resolvers[path] = [resolver];
    } else {
      resolvers[path].push(resolver);
    }
  }

  if (fetchpromises[path]) return fetchpromises[path];

  const { projectPath } = client.readQuery({ query: projectPathQuery });
  const { escapedRef } = client.readQuery({ query: refQuery });

  fetchpromises[path] = axios
    .get(
      `${gon.relative_url_root}/${projectPath}/-/refs/${escapedRef}/logs_tree/${encodeURIComponent(
        path.replace(/^\//, ''),
      )}`,
      {
        params: { format: 'json', offset: nextOffset || offset },
      },
    )
    .then(({ data: newData, headers }) => {
      const headerLogsOffset = headers['more-logs-offset'];
      const sourceData = client.readQuery({ query: commitsQuery });
      const data = produce(sourceData, (draftState) => {
        draftState.commits.push(...normalizeData(newData, path));
      });
      client.writeQuery({
        query: commitsQuery,
        data,
      });

      resolvers[path].forEach((r) => resolveCommit(data.commits, path, r));

      delete fetchpromises[path];

      if (headerLogsOffset) {
        setNextOffset(null);
        fetchLogsTree(client, path, headerLogsOffset);
      } else {
        delete resolvers[path];
        maxOffset = null;
        setNextOffset(null);
      }
    });

  return fetchpromises[path];
}
