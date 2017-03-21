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

  add(userId) {
    return new Promise((resolve, reject) => {
      this.sidebarAssigneeResource.update({ [this.field]: userId })
        .then((response) => {
          resolve(JSON.parse(response.body))
        }, (response) => {
          reject(response)
        });
    });
  }
}
