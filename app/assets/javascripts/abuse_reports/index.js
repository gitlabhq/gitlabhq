import Vue from 'vue';
import LinksToSpamInput from './components/links_to_spam_input.vue';

export const initLinkToSpam = () => {
  const el = document.getElementById('js-links-to-spam');

  if (!el) return false;

  const { links } = el.dataset;

  return new Vue({
    el,
    name: 'LinksToSpamRoot',
    render(createElement) {
      return createElement(LinksToSpamInput, {
        props: {
          previousLinks: JSON.parse(links),
        },
      });
    },
  });
};
