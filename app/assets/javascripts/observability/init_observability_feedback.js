import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ObservabilityFeedback from '~/observability/components/observability_feedback.vue';

export default () => {
  const el = document.getElementById('js-observability-feedback');
  if (!el) return null;
  return initVueApp({ el, name: 'ObservabilityFeedbackRoot', component: ObservabilityFeedback });
};
