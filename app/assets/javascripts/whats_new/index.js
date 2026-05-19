import Vue from 'vue';
import { pinia } from '~/pinia/instance';
import WhatsNewApp from './components/app.vue';
import { useWhatsNew } from './store';

let whatsNewApp;

export default (dataset = {}, withClose, updateHelpMenuUnreadBadge) => {
  if (whatsNewApp) {
    useWhatsNew().openDrawer();
  } else {
    const { versionDigest, initialReadArticles, markAsReadPath, mostRecentReleaseItemsCount } =
      dataset;
    const el = document.createElement('div');
    document.body.append(el);
    whatsNewApp = new Vue({
      el,
      name: 'WhatsNewAppRoot',
      pinia,
      render(createElement) {
        return createElement(WhatsNewApp, {
          props: {
            versionDigest,
            initialReadArticles,
            markAsReadPath,
            mostRecentReleaseItemsCount,
            withClose,
            updateHelpMenuUnreadBadge,
          },
        });
      },
    });
  }
};
