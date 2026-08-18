import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import LinksToSpamInput from './components/links_to_spam_input.vue';

export const initLinkToSpam = () => {
  const el = document.getElementById('js-links-to-spam');

  if (!el) return false;

  const { links } = el.dataset;

  return initVueApp({
    el,
    name: 'LinksToSpamRoot',
    component: LinksToSpamInput,
    props: {
      previousLinks: JSON.parse(links),
    },
  });
};
