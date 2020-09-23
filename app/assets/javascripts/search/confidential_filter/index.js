import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import DropdownFilter from '../components/dropdown_filter.vue';
import {
  FILTER_HEADER,
  FILTER_PARAM,
  FILTER_STATES_BY_SCOPE,
  FILTER_STATES,
  SCOPES,
} from './constants';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-search-filter-by-confidential');

  if (!el) return false;

  return new Vue({
    el,
    data() {
      return { ...el.dataset };
    },

    render(createElement) {
      return createElement(DropdownFilter, {
        props: {
          initialFilter: this.filter,
          filtersArray: FILTER_STATES_BY_SCOPE[this.scope],
          filters: FILTER_STATES,
          header: FILTER_HEADER,
          param: FILTER_PARAM,
          scope: this.scope,
          supportedScopes: Object.values(SCOPES),
        },
      });
    },
  });
};
