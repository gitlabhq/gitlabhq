import Vue from 'vue';
import Wikis from './wikis';
import WikiContent from './components/wiki_content.vue';
import WikiExport from './components/wiki_export.vue';

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

const mountWikiExportApp = () => {
  const el = document.querySelector('#js-export-actions');

  if (!el) return false;
  const { target, title, stylesheet } = JSON.parse(el.dataset.options);

  return new Vue({
    el,
    provide: {
      target,
      title,
      stylesheet,
    },
    render(createElement) {
      return createElement(WikiExport);
    },
  });
};

export const mountApplications = () => {
  // eslint-disable-next-line no-new
  new Wikis();
  mountWikiContentApp();
  mountWikiExportApp();
};
