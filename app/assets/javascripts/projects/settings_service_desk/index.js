import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ServiceDeskRoot from './components/service_desk_root.vue';

export default () => {
  const el = document.querySelector('.js-service-desk-setting-root');

  if (!el) {
    return false;
  }

  const {
    customEmail,
    customEmailEnabled,
    enabled,
    endpoint,
    incomingEmail,
    outgoingName,
    projectKey,
    selectedTemplate,
    templates,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      customEmail,
      customEmailEnabled: parseBoolean(customEmailEnabled),
      endpoint,
      initialIncomingEmail: incomingEmail,
      initialIsEnabled: parseBoolean(enabled),
      outgoingName,
      projectKey,
      selectedTemplate,
      templates: JSON.parse(templates),
    },
    render: (createElement) => createElement(ServiceDeskRoot),
  });
};
