import Vue from 'vue';
import vueResource from 'vue-resource';
import '../../../vue_shared/vue_resource_interceptor';

Vue.use(vueResource);

class ServiceDeskService {
  constructor(endpoint) {
    this.serviceDeskResource = Vue.resource(`${endpoint}`);
  }

  fetchIncomingEmail() {
    return this.serviceDeskResource.get()
      .then((res) => {
        const email = res.data.service_desk_address;
        if (!email) {
          throw new Error('Response didn\'t include `service_desk_address`');
        }

        return email;
      });
  }

  toggleServiceDesk(enable) {
    return this.serviceDeskResource.update({
      service_desk_enabled: enable,
    })
      .then((res) => {
        const email = res.data.service_desk_address;
        if (enable && !email) {
          throw new Error('Response didn\'t include `service_desk_address`');
        }

        return email;
      });
  }
}

export default ServiceDeskService;
