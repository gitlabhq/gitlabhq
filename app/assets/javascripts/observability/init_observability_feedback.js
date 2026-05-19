import Vue from 'vue';
import ObservabilityFeedback from '~/observability/components/observability_feedback.vue';

export default () => {
  const el = document.getElementById('js-observability-feedback');
  if (!el) return null;
  return new Vue({
    el,
    name: 'ObservabilityFeedbackRoot',
    render(h) {
      return h(ObservabilityFeedback);
    },
  });
};
