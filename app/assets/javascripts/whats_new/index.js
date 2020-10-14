import Vue from 'vue';
import App from './components/app.vue';
import store from './store';

let whatsNewApp;

export default () => {
  if (whatsNewApp) {
    store.dispatch('openDrawer');
  } else {
    const whatsNewElm = document.getElementById('whats-new-app');

    whatsNewApp = new Vue({
      el: whatsNewElm,
      store,
      components: {
        App,
      },
      render(createElement) {
        return createElement('app', {
          props: {
            storageKey: whatsNewElm.getAttribute('data-storage-key'),
          },
        });
      },
    });
  }
};
