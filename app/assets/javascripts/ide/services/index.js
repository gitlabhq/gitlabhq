import axios from '~/lib/utils/axios_utils';
import Api from '~/api';

export default {
  getFileData(endpoint) {
    return axios.get(endpoint, {
      params: { format: 'json', viewer: 'none' },
    });
  },
  getRawFileData(file) {
    if (file.tempFile) {
      return Promise.resolve(file.content);
    }

    if (file.raw) {
      return Promise.resolve(file.raw);
    }

    return axios
      .get(file.rawPath, {
        params: { format: 'json' },
      })
      .then(({ data }) => data);
  },
  getBaseRawFileData(file, sha) {
    if (file.tempFile) {
      return Promise.resolve(file.baseRaw);
    }

    if (file.baseRaw) {
      return Promise.resolve(file.baseRaw);
    }

    return axios
      .get(file.rawPath.replace(`/raw/${file.branchId}/${file.path}`, `/raw/${sha}/${file.path}`), {
        params: { format: 'json' },
      })
      .then(({ data }) => data);
  },
  getProjectData(namespace, project) {
    return Api.project(`${namespace}/${project}`);
  },
  getProjectMergeRequestData(projectId, mergeRequestId, params = {}) {
    return Api.mergeRequest(projectId, mergeRequestId, params);
  },
  getProjectMergeRequestChanges(projectId, mergeRequestId) {
    return Api.mergeRequestChanges(projectId, mergeRequestId);
  },
  getProjectMergeRequestVersions(projectId, mergeRequestId) {
    return Api.mergeRequestVersions(projectId, mergeRequestId);
  },
  getBranchData(projectId, currentBranchId) {
    return Api.branchSingle(projectId, currentBranchId);
  },
  commit(projectId, payload) {
    return Api.commitMultiple(projectId, payload);
  },
  getFiles(projectUrl, branchId) {
    const url = `${projectUrl}/files/${branchId}`;
    return axios.get(url, { params: { format: 'json' } });
  },
  lastCommitPipelines({ getters }) {
    const commitSha = getters.lastCommit.id;
    return Api.commitPipelines(getters.currentProject.path_with_namespace, commitSha);
  },
};
