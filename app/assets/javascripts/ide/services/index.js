import Api from '~/api';

export default {
  commit(projectId, payload) {
    return Api.commitMultiple(projectId, payload);
  },
};
