import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import SearchSettings from '~/search_settings/components/search_settings.vue';
import { expandSection, closeSection, isExpanded } from '~/settings_panels';

const mountSearch = ({ el }) =>
  initVueApp({
    el,
    name: 'SearchSettingsRoot',
    component: SearchSettings,
    props: {
      searchRoot: document.querySelector('#content-body'),
      sectionSelector: '.js-search-settings-section, section.settings, .vue-settings-block',
      hideWhenEmptySelector: '.js-hide-when-nothing-matches-search',
      isExpandedFn: isExpanded,
    },
    events: {
      collapse: closeSection,
      expand: expandSection,
    },
  });

export default mountSearch;
