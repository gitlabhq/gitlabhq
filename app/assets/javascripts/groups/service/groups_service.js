import axios from '~/lib/utils/axios_utils';

export default class GroupsService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  getGroups(parentId, page, filterGroups, sort, archived) {
    const params = {};

    if (parentId) {
      params.parent_id = parentId;
    } else {
      // Do not send the following param for sub groups
      if (page) {
        params.page = page;
      }

      if (filterGroups) {
        params.filter = filterGroups;
      }

      if (sort) {
        params.sort = sort;
      }

      if (archived) {
        params.archived = archived;
      }
    }

    return axios.get(this.endpoint, { params });
  }

  // eslint-disable-next-line class-methods-use-this
  leaveGroup(endpoint) {
    return axios.delete(endpoint);
  }
}
