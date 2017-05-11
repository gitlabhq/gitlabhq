import Vue from 'vue';
import serviceDeskRoot from './components/service_desk_root.vue';

document.addEventListener('DOMContentLoaded', () => {
  const serviceDeskRootElement = document.querySelector('.js-service-desk-setting-root');
  if (serviceDeskRootElement) {
    // eslint-disable-next-line no-new
    new Vue({
      el: serviceDeskRootElement,
      data() {
        const dataset = serviceDeskRootElement.dataset;
        return {
          initialIsEnabled: gl.utils.convertPermissionToBoolean(
            dataset.enabled,
          ),
          endpoint: dataset.endpoint,
          incomingEmail: dataset.incomingEmail,
        };
      },
      components: {
        serviceDeskRoot,
      },
      render(createElement) {
        return createElement('service-desk-root', {
          props: {
            initialIsEnabled: this.initialIsEnabled,
            endpoint: this.endpoint,
            incomingEmail: this.incomingEmail,
          },
        });
      },
    });
  }
});
