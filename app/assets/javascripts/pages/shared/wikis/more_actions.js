import Vue from 'vue';
import WikiMoreDropdown from './components/wiki_more_dropdown.vue';

const mountWikiMoreActions = () => {
  const el = document.querySelector('#js-vue-wiki-more-actions');

  if (!el) return false;
  const { pageHeading, cloneSshUrl, cloneHttpUrl, wikiUrl, newUrl, templatesUrl } = el.dataset;

  return new Vue({
    el,
    provide: {
      pageHeading,
      cloneSshUrl,
      cloneHttpUrl,
      wikiUrl,
      newUrl,
      templatesUrl,
    },
    render(createElement) {
      return createElement(WikiMoreDropdown);
    },
  });
};

export const mountMoreActions = () => {
  mountWikiMoreActions();
};
