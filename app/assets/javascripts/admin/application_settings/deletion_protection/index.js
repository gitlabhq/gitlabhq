import Vue from 'vue';
import { parseFormProps } from './utils';
import FormGroup from './components/form_group.vue';

export const initAdminDeletionProtectionSettings = () => {
  const el = document.querySelector('#js-admin-deletion-protection-settings');

  if (!el) {
    return false;
  }

  const { deletionAdjournedPeriod } = parseFormProps(el.dataset);

  return new Vue({
    el,
    name: 'AdminDeletionProtectionSettings',
    render(createElement) {
      return createElement(FormGroup, {
        props: {
          deletionAdjournedPeriod,
        },
      });
    },
  });
};
