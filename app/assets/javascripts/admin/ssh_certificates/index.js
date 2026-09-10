import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import SshCertificatesTable from './components/table.vue';

export const initAdminSshCertificatesTable = () => {
  const el = document.getElementById('js-admin-ssh-certificate-authorities-table');

  if (!el) return false;

  return initVueApp({
    el,
    name: 'SshCertificatesTableRoot',
    component: SshCertificatesTable,
  });
};
