import Vue from 'vue';
import sidebarWeight from './components/weight/sidebar_weight.vue';

function mountWeightComponent(mediator) {
  const el = document.querySelector('.js-sidebar-weight-entry-point');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      sidebarWeight,
    },
    render: createElement => createElement('sidebar-weight', {
      props: {
        mediator,
      },
    }),
  });
}

function mount(mediator) {
  mountWeightComponent(mediator);
}

export default mount;
