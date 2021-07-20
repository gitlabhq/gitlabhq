import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import UserCallout from '~/user_callout';
import ServicePingDisabled from './components/service_ping_disabled.vue';

export default () => {
  // eslint-disable-next-line no-new
  new UserCallout();

  const emptyStateContainer = document.getElementById('js-devops-service-ping-disabled');

  if (!emptyStateContainer) return false;

  const {
    isAdmin,
    emptyStateSvgPath,
    enableServicePingPath,
    docsLink,
  } = emptyStateContainer.dataset;

  return new Vue({
    el: emptyStateContainer,
    provide: {
      isAdmin: parseBoolean(isAdmin),
      svgPath: emptyStateSvgPath,
      primaryButtonPath: enableServicePingPath,
      docsLink,
    },
    render(h) {
      return h(ServicePingDisabled);
    },
  });
};
