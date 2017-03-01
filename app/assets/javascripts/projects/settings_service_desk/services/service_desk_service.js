/* eslint-disable no-param-reassign */
import Vue from 'vue';
import vueResource from 'vue-resource';
import '../../../vue_shared/vue_resource_interceptor';

Vue.use(vueResource);

class ServiceDeskService {
  constructor(endpointRoot) {
    this.project = Vue.resource(`${endpointRoot}/fetch-incoming-service-desk-email`);
  }

  fetchIncomingEmail() {
    return this.project.get()
      .then(res => res.data.incomingEmail);
  }
}

export default ServiceDeskService;
