import Vue from 'vue';
import VisibilityLevelDropdown from './components/visibility_level_dropdown.vue';

export default () => {
  const el = document.querySelector('.js-visibility-level-dropdown');

  if (!el) {
    return null;
  }

  const { visibilityLevelOptions, defaultLevel } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(VisibilityLevelDropdown, {
        props: {
          visibilityLevelOptions: JSON.parse(visibilityLevelOptions),
          defaultLevel: Number(defaultLevel),
        },
      });
    },
  });
};
