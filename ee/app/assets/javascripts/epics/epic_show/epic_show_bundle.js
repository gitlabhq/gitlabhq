import Vue from 'vue';
import EpicShowApp from './components/epic_show_app.vue';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#epic-show-app');
  const metaData = JSON.parse(el.dataset.meta);
  const initialData = JSON.parse(el.dataset.initial);

  const props = Object.assign({}, initialData, metaData, {
    // Current iteration does not enable users
    // to delete epics
    canDestroy: false,
  });

  return new Vue({
    el,
    components: {
      'epic-show-app': EpicShowApp,
    },
    render: createElement => createElement('epic-show-app', {
      props,
    }),
  });
});
