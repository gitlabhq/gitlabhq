import Vue from 'vue';
import UsagePingDisabled from '~/admin/cohorts/components/usage_ping_disabled.vue';

document.addEventListener('DOMContentLoaded', () => {
  const emptyStateContainer = document.getElementById('js-cohorts-empty-state');

  if (!emptyStateContainer) return false;

  const { emptyStateSvgPath, enableUsagePingLink, docsLink } = emptyStateContainer.dataset;

  return new Vue({
    el: emptyStateContainer,
    provide: {
      svgPath: emptyStateSvgPath,
      primaryButtonPath: enableUsagePingLink,
      docsLink,
    },
    render(h) {
      return h(UsagePingDisabled);
    },
  });
});
