import Vue from 'vue';
import $ from 'jquery';
import { expandSection, closeSection } from '~/settings_panels';
import SearchSettings from '~/search_settings/components/search_settings.vue';

const mountSearch = ({ el }) =>
  new Vue({
    el,
    render: (h) =>
      h(SearchSettings, {
        ref: 'searchSettings',
        props: {
          searchRoot: document.querySelector('#content-body'),
          sectionSelector: 'section.settings',
        },
        on: {
          collapse: (section) => closeSection($(section)),
          expand: (section) => expandSection($(section)),
        },
      }),
  });

export default mountSearch;
