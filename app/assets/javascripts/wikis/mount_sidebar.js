import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
    editSidebarUrl,
    isEditingSidebar,
  } = el.dataset;

  return initVueApp({
    el,
    name: 'WikiSidebarRoot',
    provide: {
      hasCustomSidebar: parseBoolean(hasCustomSidebar),
      canCreate: parseBoolean(canCreate),
      sidebarPagesApi: gl.GfmAutoComplete.dataSources.wikis,
      viewAllPagesPath,
      editing,
      customSidebarContent,
      editSidebarUrl,
      isEditingSidebar: parseBoolean(isEditingSidebar),
    },
    component: WikiSidebar,
  });
};
