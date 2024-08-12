import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { normalizeData } from 'ee_else_ce/repository/utils/commit';
import { createAlert } from '~/alert';
import { COMMIT_BATCH_SIZE, I18N_COMMIT_DATA_FETCH_ERROR } from './constants';

let requestedOffsets = [];
let fetchedBatches = [];

export const isRequested = (offset) => requestedOffsets.includes(offset);

export const resetRequestedCommits = () => {
  requestedOffsets = [];
  fetchedBatches = [];
};

const addRequestedOffset = (offset) => {
  if (isRequested(offset) || offset < 0) {
    return;
  }

  requestedOffsets.push(offset);
};

const removeLeadingSlash = (path) => path.replace(/^\//, '');

// eslint-disable-next-line max-params
const fetchData = (projectPath, path, ref, offset, refType) => {
  if (fetchedBatches.includes(offset) || offset < 0) {
    return [];
  }

  fetchedBatches.push(offset);

  // using encodeURIComponent() for ref to allow # as a part of branch name
  // using encodeURI() for path to correctly display subdirectories
  const url = joinPaths(
    gon.relative_url_root || '/',
    projectPath,
    '/-/refs/',
    encodeURIComponent(ref),
    '/logs_tree/',
    encodeURI(removeLeadingSlash(path)),
  );

  return axios
    .get(url, { params: { format: 'json', offset, ref_type: refType } })
    .then(({ data }) => normalizeData(data, path))
    .catch(() => createAlert({ message: I18N_COMMIT_DATA_FETCH_ERROR }));
};

// eslint-disable-next-line max-params
export const loadCommits = async (projectPath, path, ref, offset, refType) => {
  if (isRequested(offset)) {
    return [];
  }

  // We fetch in batches of 25, so this ensures we don't refetch
  Array.from(Array(COMMIT_BATCH_SIZE)).forEach((_, i) => addRequestedOffset(offset + i));

  const commits = await fetchData(projectPath, path, ref, offset, refType);

  return commits;
};
