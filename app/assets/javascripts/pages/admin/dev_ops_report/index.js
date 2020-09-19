import Vue from 'vue';
import UserCallout from '~/user_callout';
import UsagePingDisabled from '~/admin/dev_ops_report/components/usage_ping_disabled.vue';

document.addEventListener('DOMContentLoaded', () => {
  // eslint-disable-next-line no-new
  new UserCallout();

  const emptyStateContainer = document.getElementById('js-devops-empty-state');

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
});
