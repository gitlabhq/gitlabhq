import Vue from 'vue';
import VueResource from 'vue-resource';
import '../../vue_shared/vue_resource_interceptor';

Vue.http.options.emulateJSON = true;
Vue.use(VueResource);

export default class SidebarAssigneesService {
  constructor(path, field) {
    this.field = field;
    this.path = path;
  }

  update(userIds) {
    return Vue.http.put(this.path, {
      [this.field]: userIds,
    }, { emulateJSON: true });
  }
}
