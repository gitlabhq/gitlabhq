import Vue from 'vue';
import SearchSettings from '~/search_settings/components/search_settings.vue';
import { expandSection, closeSection, isExpanded } from '~/settings_panels';

const mountSearch = ({ el }) =>
  new Vue({
    el,
    render: (h) =>
      h(SearchSettings, {
        ref: 'searchSettings',
        props: {
          searchRoot: document.querySelector('#content-body'),
          sectionSelector: '.js-search-settings-section, section.settings, .vue-settings-block',
          hideWhenEmptySelector: '.js-hide-when-nothing-matches-search',
          isExpandedFn: isExpanded,
        },
        on: {
          collapse: closeSection,
          expand: expandSection,
        },
      }),
  });

export default mountSearch;
