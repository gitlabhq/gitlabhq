import Vue from 'vue';
import { parseRailsFormFields } from '~/lib/utils/forms';
import { parseBoolean } from '~/lib/utils/common_utils';
import GroupNameAndPath from './components/group_name_and_path.vue';

export const initGroupNameAndPath = () => {
  const elements = document.querySelectorAll('.js-group-name-and-path');

  if (!elements.length) {
    return;
  }

  elements.forEach((element) => {
    const fields = parseRailsFormFields(element);
    const { basePath, mattermostEnabled } = element.dataset;

    return new Vue({
      el: element,
      provide: {
        fields,
        basePath,
        mattermostEnabled: parseBoolean(mattermostEnabled),
      },
      render(h) {
        return h(GroupNameAndPath);
      },
    });
  });
};
