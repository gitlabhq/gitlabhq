import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pinia } from '~/pinia/instance';
import WhatsNewApp from './components/app.vue';
import { useWhatsNew } from './store';

let whatsNewApp;

export default (dataset = {}, updateHelpMenuUnreadBadge) => {
  if (whatsNewApp) {
    useWhatsNew().openDrawer();
  } else {
    const {
      versionDigest,
      initialReadArticles,
      markAsReadPath,
      mostRecentReleaseItemsCount,
      placement,
    } = dataset;
    const el = document.createElement('div');
    document.body.append(el);
    whatsNewApp = initVueApp({
      el,
      name: 'WhatsNewAppRoot',
      pinia,
      component: WhatsNewApp,
      props: {
        versionDigest,
        initialReadArticles,
        markAsReadPath,
        mostRecentReleaseItemsCount,
        updateHelpMenuUnreadBadge,
        placement,
      },
    });
  }
};
