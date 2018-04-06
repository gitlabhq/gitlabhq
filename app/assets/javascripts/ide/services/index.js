import Vue from 'vue';
import VueResource from 'vue-resource';
import Api from '~/api';

Vue.use(VueResource);

export default {
  getTreeData(endpoint) {
    return Vue.http.get(endpoint, { params: { format: 'json' } });
  },
  getFileData(endpoint) {
    return Vue.http.get(endpoint, { params: { format: 'json' } });
  },
  getRawFileData(file) {
    if (file.tempFile) {
      return Promise.resolve(file.content);
    }

    if (file.raw) {
      return Promise.resolve(file.raw);
    }

    return Vue.http.get(file.rawPath, { params: { format: 'json' } }).then(res => res.text());
  },
  getBaseRawFileData(file, sha) {
    if (file.tempFile) {
      return Promise.resolve(file.baseRaw);
    }

    if (file.baseRaw) {
      return Promise.resolve(file.baseRaw);
    }

    return Vue.http
      .get(file.rawPath.replace(`/raw/${file.branchId}/${file.path}`, `/raw/${sha}/${file.path}`), {
        params: { format: 'json' },
      })
      .then(res => res.text());
  },
  getProjectData(namespace, project) {
    return Api.project(`${namespace}/${project}`);
  },
  getProjectMergeRequestData(projectId, mergeRequestId) {
    return Api.mergeRequest(projectId, mergeRequestId);
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
  createBranch(projectId, payload) {
    const url = Api.buildUrl(Api.createBranchPath).replace(':id', projectId);

    return Vue.http.post(url, payload);
  },
  commit(projectId, payload) {
    return Api.commitMultiple(projectId, payload);
  },
  getTreeLastCommit(endpoint) {
    return Vue.http.get(endpoint, {
      params: {
        format: 'json',
      },
    });
  },
  getFiles(projectUrl, branchId) {
    const url = `${projectUrl}/files/${branchId}`;
    return Vue.http.get(url, {
      params: {
        format: 'json',
      },
    });
  },
};
