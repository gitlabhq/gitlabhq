import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProjectSelect from './project_select.vue';

const SELECTOR = '.js-vue-project-select';

export const initProjectSelects = () => {
  if (process.env.NODE_ENV !== 'production' && document.querySelector(SELECTOR) === null) {
    // eslint-disable-next-line no-console
    console.warn(`Attempted to initialize ProjectSelect but '${SELECTOR}' not found in the page`);
  }

  document.querySelectorAll(SELECTOR).forEach((el) => {
    const { label, inputName, inputId, groupId, selected: initialSelection } = el.dataset;
    const clearable = parseBoolean(el.dataset.clearable);

    return new Vue({
      el,
      name: 'ProjectSelectRoot',
      render(createElement) {
        return createElement(ProjectSelect, {
          props: {
            label,
            inputName,
            inputId,
            groupId,
            initialSelection,
            clearable,
          },
        });
      },
    });
  });
};
