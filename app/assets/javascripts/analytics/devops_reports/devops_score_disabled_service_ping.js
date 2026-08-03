import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import UserCallout from '~/user_callout';
import ServicePingDisabled from './components/service_ping_disabled.vue';

export default () => {
  // eslint-disable-next-line no-new
  new UserCallout();

  const emptyStateContainer = document.getElementById('js-devops-service-ping-disabled');

  if (!emptyStateContainer) return false;

  const { isAdmin, enableServicePingPath } = emptyStateContainer.dataset;

  return initVueApp({
    el: emptyStateContainer,
    name: 'ServicePingDisabledRoot',
    provide: {
      isAdmin: parseBoolean(isAdmin),
      primaryButtonPath: enableServicePingPath,
    },
    component: ServicePingDisabled,
  });
};
