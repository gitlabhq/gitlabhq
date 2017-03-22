import Vue from 'vue';
import VueResource from 'vue-resource';

require('~/vue_shared/vue_resource_interceptor');

Vue.http.options.emulateJSON = true;
Vue.use(VueResource);

export default class SidebarAssigneesService {
  constructor(path, field) {
    this.field = field;
    this.sidebarAssigneeResource = Vue.resource(path);
  }

  update(userIds) {
    return this.sidebarAssigneeResource.update({
      [this.field]: userIds
    });
  }
}
