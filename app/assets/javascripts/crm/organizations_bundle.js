import Vue from 'vue';
import CrmOrganizationsRoot from './components/organizations_root.vue';

export default () => {
  const el = document.getElementById('js-crm-organizations-app');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(CrmOrganizationsRoot);
    },
  });
};
