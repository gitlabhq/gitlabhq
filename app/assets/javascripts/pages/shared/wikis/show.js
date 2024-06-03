import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import Wikis from './wikis';
import WikiContentApp from './app.vue';

const mountWikiContentApp = () => {
  const el = document.querySelector('#js-vue-wiki-content-app');

  if (!el) return false;
  const {
    pageTitle,
    contentApi,
    showEditButton,
    isPageTemplate,
    isPageHistorical,
    editButtonUrl,
    lastVersion,
    pageVersion,
    authorUrl,
    wikiPath,
    cloneSshUrl,
    cloneHttpUrl,
    newUrl,
    historyUrl,
    templatesUrl,
    cloneLinkClass,
    wikiUrl,
    pagePersisted,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      pageTitle,
      contentApi,
      showEditButton: parseBoolean(showEditButton),
      isPageTemplate: parseBoolean(isPageTemplate),
      isPageHistorical: parseBoolean(isPageHistorical),
      editButtonUrl,
      lastVersion,
      pageVersion: JSON.parse(pageVersion),
      authorUrl,
      wikiPath,
      cloneSshUrl,
      cloneHttpUrl,
      newUrl,
      historyUrl,
      csrfToken: csrf.token,
      templatesUrl,
      cloneLinkClass,
      wikiUrl,
      pagePersisted: parseBoolean(pagePersisted),
    },
    render(createElement) {
      return createElement(WikiContentApp);
    },
  });
};

export const mountApplications = () => {
  mountWikiContentApp();
  // eslint-disable-next-line no-new
  new Wikis();
};
