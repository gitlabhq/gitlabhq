import Vue from 'vue';
import App from './components/app.vue';
import Trigger from './components/trigger.vue';
import store from './store';

export default () => {
  const whatsNewElm = document.getElementById('whats-new-app');

  // eslint-disable-next-line no-new
  new Vue({
    el: whatsNewElm,
    store,
    components: {
      App,
    },
    render(createElement) {
      return createElement('app', {
        props: {
          features: whatsNewElm.getAttribute('data-features'),
        },
      });
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: document.getElementById('whats-new-trigger'),
    store,
    components: {
      Trigger,
    },

    render(createElement) {
      return createElement('trigger');
    },
  });
};
