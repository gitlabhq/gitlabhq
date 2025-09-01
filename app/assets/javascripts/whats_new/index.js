import Vue from 'vue';
import WhatsNewApp from './components/app.vue';
import store from './store';

let whatsNewApp;

export default (dataset = {}, withClose) => {
  if (whatsNewApp) {
    store.dispatch('openDrawer');
  } else {
    const { versionDigest, initialReadArticles, markAsReadPath, mostRecentReleaseItemsCount } =
      dataset;
    const el = document.createElement('div');
    document.body.append(el);
    whatsNewApp = new Vue({
      el,
      store,
      render(createElement) {
        return createElement(WhatsNewApp, {
          props: {
            versionDigest,
            initialReadArticles,
            markAsReadPath,
            mostRecentReleaseItemsCount,
            withClose,
          },
        });
      },
    });
  }
};
