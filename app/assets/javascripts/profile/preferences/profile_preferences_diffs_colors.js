import Vue from 'vue';
import DiffsColors from './components/diffs_colors.vue';

export default () => {
  const el = document.querySelector('#js-profile-preferences-diffs-colors-app');

  if (!el) return false;

  const { deletion, addition } = el.dataset;

  return new Vue({
    el,
    provide: {
      deletion,
      addition,
    },
    render(createElement) {
      return createElement(DiffsColors);
    },
  });
};
