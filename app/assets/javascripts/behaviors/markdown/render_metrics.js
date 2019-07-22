import Vue from 'vue';
import Metrics from '~/monitoring/components/embed.vue';
import { createStore } from '~/monitoring/stores';

// TODO: Handle copy-pasting - https://gitlab.com/gitlab-org/gitlab-ce/issues/64369.
export default function renderMetrics(elements) {
  if (!elements.length) {
    return;
  }

  elements.forEach(element => {
    const { dashboardUrl } = element.dataset;
    const MetricsComponent = Vue.extend(Metrics);

    // eslint-disable-next-line no-new
    new MetricsComponent({
      el: element,
      store: createStore(),
      propsData: {
        dashboardUrl,
      },
    });
  });
}
