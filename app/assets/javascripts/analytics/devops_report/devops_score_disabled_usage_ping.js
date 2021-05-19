import Vue from 'vue';
import UserCallout from '~/user_callout';
import UsagePingDisabled from './components/usage_ping_disabled.vue';

export default () => {
  // eslint-disable-next-line no-new
  new UserCallout();

  const emptyStateContainer = document.getElementById('js-devops-usage-ping-disabled');

  if (!emptyStateContainer) return false;

  const { emptyStateSvgPath, enableUsagePingLink, docsLink, isAdmin } = emptyStateContainer.dataset;

  return new Vue({
    el: emptyStateContainer,
    provide: {
      isAdmin: Boolean(isAdmin),
      svgPath: emptyStateSvgPath,
      primaryButtonPath: enableUsagePingLink,
      docsLink,
    },
    render(h) {
      return h(UsagePingDisabled);
    },
  });
};
