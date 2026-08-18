import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseFormProps } from './utils';
import FormGroup from './components/form_group.vue';

export const initAdminDeletionProtectionSettings = () => {
  const el = document.querySelector('#js-admin-deletion-protection-settings');

  if (!el) {
    return false;
  }

  const { deletionAdjournedPeriod } = parseFormProps(el.dataset);

  return initVueApp({
    el,
    name: 'AdminDeletionProtectionSettings',
    component: FormGroup,
    props: {
      deletionAdjournedPeriod,
    },
  });
};
