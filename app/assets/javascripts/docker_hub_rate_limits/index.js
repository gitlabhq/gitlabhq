import Vue from 'vue';
import DockerHubRateLimitsAlert from '~/vue_shared/components/docker_hub_rate_limits_alert.vue';

export default (selector = '#js-docker-hub-rate-limits-alert') => {
  const containerEl = document.querySelector(selector);

  if (!containerEl) {
    return false;
  }

  return new Vue({
    el: containerEl,
    render(createElement) {
      return createElement(DockerHubRateLimitsAlert);
    },
  });
};
