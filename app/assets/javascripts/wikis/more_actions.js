import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import WikiMoreDropdown from './components/wiki_more_dropdown.vue';

const mountWikiMoreActions = () => {
  const el = document.querySelector('#js-vue-wiki-more-actions');

  if (!el) return false;
  const { pageHeading, cloneSshUrl, cloneHttpUrl, wikiUrl, newUrl, templatesUrl } = el.dataset;

  return initVueApp({
    el,
    name: 'WikiMoreDropdownRoot',
    provide: {
      pageHeading,
      cloneSshUrl,
      cloneHttpUrl,
      wikiUrl,
      newUrl,
      templatesUrl,
    },
    component: WikiMoreDropdown,
  });
};

export const mountMoreActions = () => {
  mountWikiMoreActions();
};
