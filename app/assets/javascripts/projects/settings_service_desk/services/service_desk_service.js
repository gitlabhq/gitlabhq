import Vue from 'vue';
import vueResource from 'vue-resource';

Vue.use(vueResource);

class ServiceDeskService {
  constructor(endpoint) {
    this.serviceDeskResource = Vue.resource(`${endpoint}`);
  }

  fetchIncomingEmail() {
    return this.serviceDeskResource.get();
  }

  toggleServiceDesk(enable) {
    return this.serviceDeskResource.update({
      service_desk_enabled: enable,
    });
  }
}

export default ServiceDeskService;
