import axios from '~/lib/utils/axios_utils';
import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';
import Api from '~/api';
import getUserPermissions from '../queries/getUserPermissions.query.graphql';
import gqClient from './gql';

const fetchApiProjectData = projectPath => Api.project(projectPath).then(({ data }) => data);

const fetchGqlProjectData = projectPath =>
  gqClient
    .query({
      query: getUserPermissions,
      variables: { projectPath },
    })
    .then(({ data }) => data.project);

export default {
  getFileData(endpoint) {
    return axios.get(endpoint, {
      params: { format: 'json', viewer: 'none' },
    });
  },
  getRawFileData(file) {
    if (file.tempFile && !file.prevPath) {
      return Promise.resolve(file.content);
    }

    if (file.raw || !file.rawPath) {
      return Promise.resolve(file.raw);
    }

    return axios
      .get(file.rawPath, {
        transformResponse: [f => f],
      })
      .then(({ data }) => data);
  },
  getBaseRawFileData(file, sha) {
    if (file.tempFile || file.baseRaw) return Promise.resolve(file.baseRaw);

    // if files are renamed, their base path has changed
    const filePath =
      file.mrChange && file.mrChange.renamed_file ? file.mrChange.old_path : file.path;

    return axios
      .get(
        joinPaths(
          gon.relative_url_root || '/',
          file.projectId,
          '-',
          'raw',
          sha,
          escapeFileUrl(filePath),
        ),
        {
          transformResponse: [f => f],
        },
      )
      .then(({ data }) => data);
  },
  getProjectData(namespace, project) {
    const projectPath = `${namespace}/${project}`;

    return Promise.all([fetchApiProjectData(projectPath), fetchGqlProjectData(projectPath)]).then(
      ([apiProjectData, gqlProjectData]) => ({
        data: {
          ...apiProjectData,
          ...gqlProjectData,
        },
      }),
    );
  },
  getProjectMergeRequests(projectId, params = {}) {
    return Api.projectMergeRequests(projectId, params);
  },
  getProjectMergeRequestData(projectId, mergeRequestId, params = {}) {
    return Api.projectMergeRequest(projectId, mergeRequestId, params);
  },
  getProjectMergeRequestChanges(projectId, mergeRequestId) {
    return Api.projectMergeRequestChanges(projectId, mergeRequestId);
  },
  getProjectMergeRequestVersions(projectId, mergeRequestId) {
    return Api.projectMergeRequestVersions(projectId, mergeRequestId);
  },
  getBranchData(projectId, currentBranchId) {
    return Api.branchSingle(projectId, currentBranchId);
  },
  commit(projectId, payload) {
    return Api.commitMultiple(projectId, payload);
  },
  getFiles(projectPath, ref) {
    const url = `${gon.relative_url_root}/${projectPath}/-/files/${ref}`;
    return axios.get(url, { params: { format: 'json' } });
  },
  lastCommitPipelines({ getters }) {
    const commitSha = getters.lastCommit.id;
    return Api.commitPipelines(getters.currentProject.path_with_namespace, commitSha);
  },
};
