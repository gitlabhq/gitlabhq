import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class SidebarService {
  constructor(endpoint) {
    if (!SidebarService.singleton) {
      this.endpoint = endpoint;

      SidebarService.singleton = this;
    }

    return SidebarService.singleton;
  }

  get() {
    return Vue.http.get(this.endpoint);
  }

  update(key, data) {
    return Vue.http.put(this.endpoint, {
      [key]: data,
    }, {
      emulateJSON: true,
    });
  }
}
