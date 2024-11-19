import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import GroupSelect from './group_select.vue';

const SELECTOR = '.js-vue-group-select';

export const initGroupSelects = () => {
  if (process.env.NODE_ENV !== 'production' && document.querySelector(SELECTOR) === null) {
    // eslint-disable-next-line no-console
    console.warn(`Attempted to initialize GroupSelect but '${SELECTOR}' not found in the page`);
  }

  [...document.querySelectorAll(SELECTOR)].forEach((el) => {
    const {
      parentId: parentGroupID,
      groupsFilter,
      label,
      description,
      inputName,
      inputId,
      selected: initialSelection,
      testid,
    } = el.dataset;
    const clearable = parseBoolean(el.dataset.clearable);

    return new Vue({
      el,
      components: {
        GroupSelect,
      },
      render(createElement) {
        return createElement(GroupSelect, {
          props: {
            label,
            description,
            inputName,
            initialSelection,
            parentGroupID,
            groupsFilter,
            inputId,
            clearable,
          },
          attrs: {
            'data-testid': testid,
          },
        });
      },
    });
  });
};
