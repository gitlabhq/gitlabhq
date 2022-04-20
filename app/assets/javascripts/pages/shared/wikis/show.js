import Vue from 'vue';
import Wikis from './wikis';
import WikiContent from './components/wiki_content.vue';

const mountWikiContentApp = () => {
  const el = document.querySelector('.js-async-wiki-page-content');

  if (el) {
    const { getWikiContentUrl } = el.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      render(createElement) {
        return createElement(WikiContent, {
          props: { getWikiContentUrl },
        });
      },
    });
  }
};

export const mountApplications = () => {
  // eslint-disable-next-line no-new
  new Wikis();
  mountWikiContentApp();
};
