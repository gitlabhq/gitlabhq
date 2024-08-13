import axios from '~/lib/utils/axios_utils';

export default class GroupsService {
  constructor(endpoint, initialSort) {
    this.endpoint = endpoint;
    this.initialSort = initialSort;
  }

  // eslint-disable-next-line max-params
  getGroups(parentId, page, filterGroups, sort) {
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

      if (sort || this.initialSort) {
        params.sort = sort || this.initialSort;
      }
    }

    return axios.get(this.endpoint, { params });
  }

  // eslint-disable-next-line class-methods-use-this
  leaveGroup(endpoint) {
    return axios.delete(endpoint);
  }
}
