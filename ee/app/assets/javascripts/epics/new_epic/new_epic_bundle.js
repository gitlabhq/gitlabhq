import Vue from 'vue';
import NewEpicApp from './components/new_epic.vue';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#new-epic-app');
  const props = el.dataset;

  return new Vue({
    el,
    components: {
      'new-epic-app': NewEpicApp,
    },
    render: createElement => createElement('new-epic-app', {
      props,
    }),
  });
});
