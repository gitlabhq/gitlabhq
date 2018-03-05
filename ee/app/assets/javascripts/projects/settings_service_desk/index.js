import Vue from 'vue';
import { convertPermissionToBoolean } from '~/lib/utils/common_utils';
import serviceDeskRoot from './components/service_desk_root.vue';

export default () => {
  const serviceDeskRootElement = document.querySelector('.js-service-desk-setting-root');
  if (serviceDeskRootElement) {
    // eslint-disable-next-line no-new
    new Vue({
      el: serviceDeskRootElement,
      components: {
        serviceDeskRoot,
      },
      data() {
        const dataset = serviceDeskRootElement.dataset;
        return {
          initialIsEnabled: convertPermissionToBoolean(
            dataset.enabled,
          ),
          endpoint: dataset.endpoint,
          incomingEmail: dataset.incomingEmail,
        };
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
};
