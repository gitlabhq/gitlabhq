import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import Form from './components/form.vue';

export default () => {
  const el = document.querySelector('.js-dormant-project-deletion-form');

  if (!el) {
    return false;
  }

  const {
    deleteDormantProjects,
    dormantProjectsDeleteAfterMonths,
    dormantProjectsMinSizeMb,
    dormantProjectsSendWarningEmailAfterMonths,
  } = el.dataset;

  return initVueApp({
    el,
    name: 'DormantProjectDeletion',
    component: Form,
    props: {
      deleteDormantProjects: parseBoolean(deleteDormantProjects),
      dormantProjectsDeleteAfterMonths: parseInt(dormantProjectsDeleteAfterMonths, 10),
      dormantProjectsMinSizeMb: parseInt(dormantProjectsMinSizeMb, 10),
      dormantProjectsSendWarningEmailAfterMonths: parseInt(
        dormantProjectsSendWarningEmailAfterMonths,
        10,
      ),
    },
  });
};
