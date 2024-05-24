import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import Wikis from './wikis';
import WikiContent from './components/wiki_content.vue';
import WikiMoreDropdown from './components/wiki_more_dropdown.vue';

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

const mountWikiMoreDropdownApp = () => {
  const el = document.querySelector('#js-wiki-more-actions');

  if (!el) return false;
  const {
    wikiPath,
    cloneSshUrl,
    cloneHttpUrl,
    newUrl,
    history,
    pageTitle,
    templatesUrl,
    cloneLinkClass,
    deleteWikiUrl,
    pagePersisted,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      wikiPath,
      cloneSshUrl,
      cloneHttpUrl,
      newUrl,
      history,
      pageTitle,
      csrfToken: csrf.token,
      templatesUrl,
      cloneLinkClass,
      deleteWikiUrl,
      pagePersisted: parseBoolean(pagePersisted),
    },
    render(createElement) {
      return createElement(WikiMoreDropdown);
    },
  });
};

export const mountApplications = () => {
  // eslint-disable-next-line no-new
  new Wikis();
  mountWikiContentApp();
  mountWikiMoreDropdownApp();
};
