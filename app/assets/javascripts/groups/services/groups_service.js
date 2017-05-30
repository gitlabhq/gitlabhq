/* eslint-disable class-methods-use-this */

import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class GroupsService {
  constructor(endpoint) {
    this.groups = Vue.resource(endpoint);
    this.groups = Vue.resource(endpoint);
  }

  getGroups(parentId, page) {
    const data = {};

    if (parentId) {
      data.parent_id = parentId;
      // Do not send this param for sub groups
    } else if (page) {
      data.page = page;
    }

    return this.groups.get(data);
  }

  leaveGroup(endpoint) {
    return Vue.http.delete(endpoint);
  }
}
