import Vue from 'vue';
import IntegrationOverrides from './components/integration_overrides.vue';

export default () => {
  const el = document.querySelector('.js-vue-integration-overrides');

  if (!el) {
    return null;
  }

  const { editPath, overridesPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      editPath,
    },
    render(createElement) {
      return createElement(IntegrationOverrides, {
        props: {
          overridesPath,
        },
      });
    },
  });
};
