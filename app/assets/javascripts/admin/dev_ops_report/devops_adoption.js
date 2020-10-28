import Vue from 'vue';
import DevopsAdoptionApp from './components/devops_adoption_app.vue';

export default () => {
  const el = document.querySelector('.js-devops-adoption');

  if (!el) return false;

  const { emptyStateSvgPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      emptyStateSvgPath,
    },
    render(h) {
      return h(DevopsAdoptionApp);
    },
  });
};
