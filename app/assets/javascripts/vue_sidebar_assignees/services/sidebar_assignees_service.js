import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class SidebarAssigneesService {
  constructor(path) {
    this.sidebarAssigneeResource = Vue.resource(path);
  }

  save(data) {
    return this.sidebarAssigneeResource.save(data);
  }
}
