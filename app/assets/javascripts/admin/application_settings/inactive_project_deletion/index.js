import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import Form from './components/form.vue';

export default () => {
  const el = document.querySelector('.js-inactive-project-deletion-form');

  if (!el) {
    return false;
  }

  const {
    deleteInactiveProjects,
    inactiveProjectsDeleteAfterMonths,
    inactiveProjectsMinSizeMb,
    inactiveProjectsSendWarningEmailAfterMonths,
  } = el.dataset;

  return new Vue({
    el,
    name: 'InactiveProjectDeletion',
    render(createElement) {
      return createElement(Form, {
        props: {
          deleteInactiveProjects: parseBoolean(deleteInactiveProjects),
          inactiveProjectsDeleteAfterMonths: parseInt(inactiveProjectsDeleteAfterMonths, 10),
          inactiveProjectsMinSizeMb: parseInt(inactiveProjectsMinSizeMb, 10),
          inactiveProjectsSendWarningEmailAfterMonths: parseInt(
            inactiveProjectsSendWarningEmailAfterMonths,
            10,
          ),
        },
      });
    },
  });
};
