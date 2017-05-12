import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class GroupsService {
  constructor(endpoint) {
    this.groups = Vue.resource(endpoint);
  }

  getGroups(parentId) {
    let data = {};

    if (parentId) {
      data = {
        parent_id: parentId,
      };
    }

    return this.groups.get(data);
  }
}
