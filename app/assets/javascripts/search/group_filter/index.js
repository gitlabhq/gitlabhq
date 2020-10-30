import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import GroupFilter from './components/group_filter.vue';

Vue.use(Translate);

export default store => {
  let initialGroup;
  const el = document.getElementById('js-search-group-dropdown');

  const { initialGroupData } = el.dataset;

  initialGroup = JSON.parse(initialGroupData);
  initialGroup = convertObjectPropsToCamelCase(initialGroup, { deep: true });

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(GroupFilter, {
        props: {
          initialGroup,
        },
      });
    },
  });
};
