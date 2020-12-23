import Vue from 'vue';
import { mapState } from 'vuex';
import App from './components/app.vue';
import store from './store';
import { getStorageKey, setNotification } from './utils/notification';

let whatsNewApp;

export default (el) => {
  if (whatsNewApp) {
    store.dispatch('openDrawer');
  } else {
    whatsNewApp = new Vue({
      el,
      store,
      components: {
        App,
      },
      computed: {
        ...mapState(['open']),
      },
      watch: {
        open() {
          setNotification(el);
        },
      },
      render(createElement) {
        return createElement('app', {
          props: {
            storageKey: getStorageKey(el),
            versions: JSON.parse(el.getAttribute('data-versions')),
            gitlabDotCom: el.getAttribute('data-gitlab-dot-com'),
          },
        });
      },
    });
  }
};
