import Vue from 'vue';
import vueResource from 'vue-resource';
import '../../../vue_shared/vue_resource_interceptor';

Vue.use(vueResource);

class ServiceDeskService {
  constructor(endpoint) {
    this.serviceDeskEnabledResource = Vue.resource(`${endpoint}/service_desk_address`);
  }

  fetchIncomingEmail() {
    return this.serviceDeskEnabledResource.get()
      .then(res => res.data.incomingEmail);
  }
}

export default ServiceDeskService;
