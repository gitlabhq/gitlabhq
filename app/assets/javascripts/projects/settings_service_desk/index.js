import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ServiceDeskRoot from './components/service_desk_root.vue';

export default () => {
  const serviceDeskRootElement = document.querySelector('.js-service-desk-setting-root');
  if (serviceDeskRootElement) {
    // eslint-disable-next-line no-new
    new Vue({
      el: serviceDeskRootElement,
      components: {
        ServiceDeskRoot,
      },
      data() {
        const { dataset } = serviceDeskRootElement;
        return {
          initialIsEnabled: parseBoolean(dataset.enabled),
          endpoint: dataset.endpoint,
          incomingEmail: dataset.incomingEmail,
          selectedTemplate: dataset.selectedTemplate,
          outgoingName: dataset.outgoingName,
          projectKey: dataset.projectKey,
          templates: JSON.parse(dataset.templates),
        };
      },
      render(createElement) {
        return createElement('service-desk-root', {
          props: {
            initialIsEnabled: this.initialIsEnabled,
            endpoint: this.endpoint,
            initialIncomingEmail: this.incomingEmail,
            selectedTemplate: this.selectedTemplate,
            outgoingName: this.outgoingName,
            projectKey: this.projectKey,
            templates: this.templates,
          },
        });
      },
    });
  }
};
