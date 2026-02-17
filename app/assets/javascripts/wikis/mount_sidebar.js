import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import WikiSidebar from './components/wiki_sidebar.vue';

export const mountWikiSidebar = () => {
  const el = document.querySelector('#js-wiki-sidebar');
  if (!el) return false;

  const {
    hasCustomSidebar,
    canCreate,
    viewAllPagesPath,
    editing,
    customSidebarContent,
    hasWikiPages,
    editSidebarUrl,
    isEditingSidebar,
  } = el.dataset;

  return new Vue({
    el,
    name: 'WikiSidebarRoot',
    provide: {
      hasCustomSidebar: parseBoolean(hasCustomSidebar),
      canCreate: parseBoolean(canCreate),
      sidebarPagesApi: gl.GfmAutoComplete.dataSources.wikis,
      viewAllPagesPath,
      editing,
      customSidebarContent,
      hasWikiPages: parseBoolean(hasWikiPages),
      editSidebarUrl,
      isEditingSidebar: parseBoolean(isEditingSidebar),
    },
    render(createElement) {
      return createElement(WikiSidebar);
    },
  });
};
