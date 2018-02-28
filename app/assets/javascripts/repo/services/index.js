import Vue from 'vue';
import VueResource from 'vue-resource';
import Api from '../../api';

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

    return Vue.http.get(file.rawPath, { params: { format: 'json' } })
      .then(res => res.text());
  },
  getBranchData(projectId, currentBranch) {
    return Api.branchSingle(projectId, currentBranch);
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
};
