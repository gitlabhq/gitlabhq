import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { escapeFileUrl } from '../stores/utils';
import Api from '~/api';

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

    if (file.raw) {
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
    return Api.project(`${namespace}/${project}`);
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
  getFiles(projectUrl, ref) {
    const url = `${projectUrl}/files/${ref}`;
    return axios.get(url, { params: { format: 'json' } });
  },
  lastCommitPipelines({ getters }) {
    const commitSha = getters.lastCommit.id;
    return Api.commitPipelines(getters.currentProject.path_with_namespace, commitSha);
  },
};
