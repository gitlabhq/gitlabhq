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
    const {
      label,
      inputName,
      inputId,
      groupId,
      userId,
      orderBy,
      selected: initialSelection,
    } = el.dataset;
    const block = parseBoolean(el.dataset.block);
    const withShared = parseBoolean(el.dataset.withShared);
    const includeSubgroups = parseBoolean(el.dataset.includeSubgroups);
    const membership = parseBoolean(el.dataset.membership);
    const hasHtmlLabel = parseBoolean(el.dataset.hasHtmlLabel);

    return new Vue({
      el,
      name: 'ProjectSelectRoot',
      render(createElement) {
        return createElement(ProjectSelect, {
          props: {
            label,
            hasHtmlLabel,
            inputName,
            inputId,
            groupId,
            userId,
            orderBy,
            block,
            withShared,
            includeSubgroups,
            membership,
            initialSelection,
          },
        });
      },
    });
  });
};
