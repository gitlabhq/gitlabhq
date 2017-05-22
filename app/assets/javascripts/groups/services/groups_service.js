import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class GroupsService {
  constructor(endpoint) {
    this.groups = Vue.resource(endpoint);
  }

  getGroups(parentId, page = 1) {
    const data = {};

    if (parentId) {
      data.parent_id = parentId;
    }

    if (page) {
      data.page = page;
    }

    return this.groups.get(data);
  }
}
