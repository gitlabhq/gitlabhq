import Vue from 'vue';
import IntegrationOverrides from './components/integration_overrides.vue';

export default () => {
  const el = document.querySelector('.js-vue-integration-overrides');

  if (!el) {
    return null;
  }

  const { overridesPath } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(IntegrationOverrides, {
        props: {
          overridesPath,
        },
      });
    },
  });
};
