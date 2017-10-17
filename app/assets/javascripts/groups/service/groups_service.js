import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class GroupsService {
  constructor(endpoint) {
    this.groups = Vue.resource(endpoint);
  }

  getGroups(parentId, page, filterGroups, sort, archived) {
    const data = {};

    if (parentId) {
      data.parent_id = parentId;
    } else {
      // Do not send the following param for sub groups
      if (page) {
        data.page = page;
      }

      if (filterGroups) {
        data.filter = filterGroups;
      }

      if (sort) {
        data.sort = sort;
      }

      if (archived) {
        data.archived = archived;
      }
    }

    return this.groups.get(data);
  }

  // eslint-disable-next-line class-methods-use-this
  leaveGroup(endpoint) {
    return Vue.http.delete(endpoint);
  }
}
